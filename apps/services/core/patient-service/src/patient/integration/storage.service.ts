import { Injectable, Logger, InternalServerErrorException } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import 'multer';
import { S3Client, PutObjectCommand } from '@aws-sdk/client-s3';

/**
 * StorageService
 * * Integration Service for Object Storage.
 * * Responsibility: Handle file uploads (Strictly Avatars for this microservice).
 * * Strategy: Supports both AWS S3 (Prod) and MinIO (Dev/Docker).
 */
@Injectable()
export class StorageService {
  private readonly s3Client: S3Client;
  private readonly bucketName: string;
  private readonly logger = new Logger(StorageService.name);

  constructor(private readonly configService: ConfigService) {
    this.bucketName = this.configService.get<string>('AWS_BUCKET_NAME') || 'dermatech-avatars';
    
    // Configuration for Hybrid Infrastructure (Local vs Cloud)
    const region = this.configService.get<string>('AWS_REGION') || 'us-east-1';
    const accessKeyId = this.configService.get<string>('AWS_ACCESS_KEY_ID');
    const secretAccessKey = this.configService.get<string>('AWS_SECRET_ACCESS_KEY');
    
    // Crucial for Docker: If AWS_ENDPOINT is set (e.g., 'http://minio:9000'), use it.
    // If undefined, AWS SDK defaults to real AWS S3 URLs.
    const endpoint = this.configService.get<string>('AWS_ENDPOINT'); 

    // --- SECURITY CHECK (Copilot Fix) ---
    // Identify the environment
    const nodeEnv = this.configService.get<string>('NODE_ENV') || 'development';
    const isProd = nodeEnv === 'production' || nodeEnv === 'prod';

    // In Production, strict validation is required. Never fallback to 'minioadmin'.
    if (isProd && (!accessKeyId || !secretAccessKey)) {
      const errorMsg = 'FATAL ERROR: AWS Credentials (ACCESS_KEY_ID or SECRET_ACCESS_KEY) are missing in Production.';
      this.logger.error(errorMsg);
      throw new Error(errorMsg); // This stops the app from booting insecurely
    }

    this.s3Client = new S3Client({
      region,
      credentials: {
        // Fallback to 'minioadmin' is now safe because we verified we are NOT in prod above
        accessKeyId: accessKeyId || 'minioadmin', 
        secretAccessKey: secretAccessKey || 'minioadmin',
      },
      endpoint: endpoint, 
      forcePathStyle: true, // Required true for MinIO/LocalStack, ignored by AWS
    });
  }

  /**
   * Uploads the avatar image to the storage bucket.
   * * @param file - The file object from Multer (Strictly typed).
   * * @param userId - Used to organize files in folders (avatars/USER_ID/...).
   * * @returns The public URL of the uploaded file.
   */
  async uploadFile(file: Express.Multer.File, userId: string): Promise<string> {
    // 1. Sanitize filename to prevent URL encoding issues
    const sanitizedOriginalName = file.originalname.replace(/\s+/g, '-');
    const key = `avatars/${userId}/${Date.now()}-${sanitizedOriginalName}`;

    try {
      // 2. Upload to S3/MinIO
      await this.s3Client.send(
        new PutObjectCommand({
          Bucket: this.bucketName,
          Key: key,
          Body: file.buffer,
          ContentType: file.mimetype,
          // 'public-read' allows the frontend to display the image without signed URLs.
          // Note: Ensure your S3 Bucket Policy allows public read for 'avatars/*' prefix.
          ACL: 'public-read', 
        }),
      );

      // 3. Dynamic URL Generation (Fixes the localhost bug)
      const endpoint = this.configService.get<string>('AWS_ENDPOINT');
      
      if (endpoint) {
        // LOCAL / DOCKER: Return the local MinIO URL
        // Example: http://localhost:9000/dermatech-avatars/avatars/123/img.jpg
        return `${endpoint}/${this.bucketName}/${key}`;
      }
      
      // PRODUCTION (AWS): Return the standard S3 URL
      // Example: https://dermatech-avatars.s3.us-east-1.amazonaws.com/avatars/123/img.jpg
      return `https://${this.bucketName}.s3.${this.configService.get('AWS_REGION')}.amazonaws.com/${key}`;

    } catch (error) {
      this.logger.error(`Storage Upload Error for UserID ${userId}`, error);
      // We throw a generic error to not leak infrastructure details to the client
      throw new InternalServerErrorException('Failed to upload profile picture');
    }
  }
}
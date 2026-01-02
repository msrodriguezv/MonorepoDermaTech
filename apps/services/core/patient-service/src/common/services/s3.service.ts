import { Injectable } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { S3Client, PutObjectCommand } from '@aws-sdk/client-s3';

@Injectable()
export class S3Service {
  private s3Client: S3Client;
  private bucketName: string;

  constructor(private configService: ConfigService) {
    this.bucketName = this.configService.get('AWS_BUCKET_NAME') || 'patient-documents';
    const isLocal = this.configService.get('NODE_ENV') === 'development';
    
    this.s3Client = new S3Client({
      region: this.configService.get('AWS_REGION') || 'us-east-1',
      credentials: {
        accessKeyId: this.configService.get('AWS_ACCESS_KEY_ID') || 'root',
        secretAccessKey: this.configService.get('AWS_SECRET_ACCESS_KEY') || 'password123',
      },
      endpoint: isLocal ? 'http://localhost:9000' : undefined,
      forcePathStyle: true,
    });
  }

  async uploadFile(file: any, userId: string): Promise<string> {
    // Generamos un nombre único
    const key = `${userId}/${Date.now()}-${file.originalname}`;

    // AQUÍ USAMOS PutObjectCommand. Si quitas el import, esto fallará.
    await this.s3Client.send(
      new PutObjectCommand({
        Bucket: this.bucketName,
        Key: key,
        Body: file.buffer,
        ContentType: file.mimetype,
      }),
    );

    return `http://localhost:9000/${this.bucketName}/${key}`;
  }
}
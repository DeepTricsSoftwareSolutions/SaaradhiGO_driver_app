# SaaradhiGO Driver App — AWS Deployment Guide

## Architecture Overview

```
Internet
  │
  ├── Route53 (domain)
  │     │
  │     └── Application Load Balancer (SSL/HTTPS)
  │           │
  │           ├── EC2 t3.medium (Node.js + PM2)
  │           │     ├── SaaradhiGO API (port 3000)
  │           │     └── Socket.io (WebSocket upgrade)
  │           └── (Scale: add more EC2 instances)
  │
  ├── RDS PostgreSQL 15 (private subnet)
  │
  └── S3 (document storage, private bucket)
        └── CloudFront CDN (optional, for fast image delivery)
```

---

## Step 1: Launch EC2 Instance

```bash
# Launch a t3.medium (2 vCPU, 4GB RAM) with Ubuntu 22.04
# Ensure Security Group allows:
#   - Port 22 (SSH)
#   - Port 80 (HTTP)
#   - Port 443 (HTTPS)
#   - Port 3000 (API - restrict to ALB only)

# SSH into instance
ssh -i your-key.pem ubuntu@<EC2_PUBLIC_IP>
```

## Step 2: Install Dependencies

```bash
# Update system
sudo apt update && sudo apt upgrade -y

# Install Node.js 20
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
sudo apt install -y nodejs

# Install PM2 globally
sudo npm install -g pm2

# Install nginx (reverse proxy)
sudo apt install -y nginx

# Install git
sudo apt install -y git
```

## Step 3: Clone & Configure

```bash
# Clone repository
git clone https://github.com/your-org/saaradhi-go-driver.git /home/ubuntu/app

# Install dependencies
cd /home/ubuntu/app/server
npm install --production

# Create production .env
cp .env.example .env.production
```

## Step 4: Production Environment Variables

Create `/home/ubuntu/app/server/.env`:

```env
NODE_ENV=production
PORT=3000

# Database (RDS)
DATABASE_URL="postgresql://username:password@your-rds-endpoint.rds.amazonaws.com:5432/saaradhigo"

# JWT Secret (generate with: openssl rand -hex 32)
JWT_SECRET=your-super-secret-256-bit-key-here

# Twilio OTP
TWILIO_ACCOUNT_SID=ACxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
TWILIO_AUTH_TOKEN=your_twilio_auth_token
TWILIO_PHONE_NUMBER=+1234567890

# AWS S3 (document uploads)
AWS_ACCESS_KEY_ID=AKIAIOSFODNN7EXAMPLE
AWS_SECRET_ACCESS_KEY=wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY
AWS_REGION=ap-south-1
S3_BUCKET_NAME=saaradhigo-documents

# Razorpay (optional — for payouts)
RAZORPAY_KEY_ID=rzp_live_xxxxxxxxxx
RAZORPAY_KEY_SECRET=your-razorpay-secret

# Allowed Origins (comma-separated)
ALLOWED_ORIGINS=https://your-domain.com,https://admin.your-domain.com
```

## Step 5: Database Setup

```bash
# Run Prisma migrations
cd /home/ubuntu/app/server
NODE_ENV=production npx prisma migrate deploy
npx prisma generate

# OR use the raw SQL schema with PostGIS
psql $DATABASE_URL < /home/ubuntu/app/database_schema.sql
```

## Step 6: Start with PM2 (Cluster Mode)

```bash
# Create PM2 ecosystem config
cat > /home/ubuntu/app/server/ecosystem.config.js << 'EOF'
module.exports = {
  apps: [{
    name: 'saaradhigo-api',
    script: 'index.js',
    cwd: '/home/ubuntu/app/server',
    instances: 'max',        // Use all CPU cores
    exec_mode: 'cluster',    // PM2 cluster mode
    env_production: {
      NODE_ENV: 'production',
      PORT: 3000,
    },
    error_file: '/var/log/saaradhigo/error.log',
    out_file: '/var/log/saaradhigo/out.log',
    merge_logs: true,
    max_memory_restart: '500M',
  }]
};
EOF

# Create log directory
sudo mkdir -p /var/log/saaradhigo
sudo chown ubuntu:ubuntu /var/log/saaradhigo

# Start the app
cd /home/ubuntu/app/server
pm2 start ecosystem.config.js --env production

# Save PM2 config (auto-restart on reboot)
pm2 save
sudo env PATH=$PATH:/usr/bin pm2 startup systemd -u ubuntu --hp /home/ubuntu
```

## Step 7: Nginx Configuration (SSL Termination)

```nginx
# /etc/nginx/sites-available/saaradhigo
server {
    listen 80;
    server_name api.your-domain.com;
    return 301 https://$server_name$request_uri;
}

server {
    listen 443 ssl http2;
    server_name api.your-domain.com;

    ssl_certificate /etc/letsencrypt/live/api.your-domain.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/api.your-domain.com/privkey.pem;
    ssl_protocols TLSv1.2 TLSv1.3;

    # API
    location /api {
        proxy_pass http://localhost:3000;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }

    # WebSocket (Socket.io)
    location /socket.io {
        proxy_pass http://localhost:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host $host;
        proxy_read_timeout 3600s;  # Keep WS connections open
    }

    # Health check
    location /health {
        proxy_pass http://localhost:3000;
    }
}
```

```bash
# Enable site
sudo ln -s /etc/nginx/sites-available/saaradhigo /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl reload nginx

# SSL with Let's Encrypt
sudo apt install certbot python3-certbot-nginx -y
sudo certbot --nginx -d api.your-domain.com
```

## Step 8: RDS PostgreSQL Setup

```bash
# Create RDS instance (console or CLI):
# - Engine: PostgreSQL 15
# - Instance: db.t3.micro (dev) or db.t3.small (prod)
# - Multi-AZ: Yes (for production)
# - Storage: 20GB (SSD)
# - Enable automatic backups: 7 days
# - VPC: Same as EC2
# - Security Group: Allow port 5432 from EC2 only

# Enable PostGIS extension after creation
psql $DATABASE_URL -c "CREATE EXTENSION IF NOT EXISTS postgis;"
```

## Step 9: S3 Bucket for Documents

```bash
# Create private S3 bucket
aws s3 mb s3://saaradhigo-documents --region ap-south-1

# Set bucket policy (private — no public access)
aws s3api put-public-access-block \
  --bucket saaradhigo-documents \
  --public-access-block-configuration "BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true"

# Create IAM user for server with minimal S3 permissions
# Policy: s3:GetObject, s3:PutObject on saaradhigo-documents/*
```

## Step 10: Flutter App Production Config

Update `mobile_flutter/lib/core/constants.dart`:
```dart
static const String apiUrl = 'https://api.your-domain.com/api';
static const String wsUrl = 'https://api.your-domain.com';
```

Build release APK:
```bash
cd mobile_flutter
flutter build apk --release
# or
flutter build appbundle --release  # For Play Store
```

## Monitoring & Alerts

```bash
# View PM2 logs
pm2 logs saaradhigo-api

# PM2 monitoring
pm2 monit

# Check status
pm2 status

# Restart without downtime
pm2 reload saaradhigo-api
```

---

## Production Checklist

- [ ] Strong `JWT_SECRET` (256-bit random: `openssl rand -hex 32`)
- [ ] Twilio SMS OTP configured
- [ ] RDS PostgreSQL with Multi-AZ enabled
- [ ] PostGIS extension enabled on RDS
- [ ] S3 bucket private — no public access
- [ ] SSL certificate via Let's Encrypt or ACM
- [ ] PM2 cluster mode running
- [ ] PM2 startup on reboot enabled
- [ ] Nginx WebSocket proxy configured
- [ ] Rate limiting active on auth routes
- [ ] CORS whitelist set to production domains only
- [ ] CloudWatch alarms for CPU > 80%
- [ ] RDS automated daily backups
- [ ] Razorpay production keys configured
- [ ] Flutter app pointing to production API URL

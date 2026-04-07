# Backend-Frontend Connection Guide

This guide explains how to connect the Node.js backend with the Flutter frontend.

## Architecture Overview

```
┌─────────────────┐      HTTP/REST      ┌─────────────────┐      SQL      ┌─────────────┐
│  Flutter App    │ ◄────────────────► │  Node.js API    │ ◄───────────► │   MySQL     │
│  (Frontend)     │      JWT Auth       │  (Backend)      │               │  (Database) │
└─────────────────┘                     └─────────────────┘               └─────────────┘
```

## Prerequisites

- Node.js 18+ installed
- MySQL 8.0+ installed and running
- Flutter SDK 3.16+ installed
- Android Studio / Xcode (for mobile emulators)

## Setup Instructions

### 1. Database Setup

1. Open MySQL and create the database:
```sql
-- Option 1: Run the schema file
mysql -u root -p < backend/database/schema.sql

-- Option 2: Copy-paste into MySQL Workbench or CLI
```

2. The schema will create:
   - `users` table - for authentication
   - `equipment_types` table - product catalog
   - `customizations` table - product options
   - `equipment_customizations` table - link products to options
   - `quotations` table - quote headers
   - `quotation_items` table - quote line items

### 2. Backend Setup

1. Navigate to the backend directory:
```bash
cd backend/quote-api
```

2. Install dependencies:
```bash
npm install
```

3. Create/update `.env` file:
```env
DB_HOST=localhost
DB_USER=root
DB_PASSWORD=your_mysql_password
DB_NAME=greentech_quote
PORT=3000
JWT_SECRET=your_secret_key_here_change_in_production
```

4. Create initial admin user:
```bash
# Start the server
npm run dev

# In another terminal, use curl or Postman to register:
curl -X POST http://localhost:3000/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{"username":"admin","password":"yourpassword"}'
```

5. The server will start on `http://localhost:3000`

### 3. Frontend Setup

1. Navigate to the frontend directory:
```bash
cd frontend/greentech_qoute
```

2. Install dependencies:
```bash
flutter pub get
```

3. Configure the API base URL in `lib/data/services/api_client.dart`:

```dart
// For Android emulator
static const String baseUrl = 'http://10.0.2.2:3000/api';

// For iOS simulator
static const String baseUrl = 'http://localhost:3000/api';

// For physical device (use your computer's IP)
static const String baseUrl = 'http://192.168.1.100:3000/api';
```

4. Run the app:
```bash
# For desktop (Windows/Mac/Linux)
flutter run -d windows

# For Android emulator
flutter run

# For iOS simulator (Mac only)
flutter run -d ios
```

## API Endpoints

### Authentication
| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/api/auth/register` | Create new user (admin only) |
| POST | `/api/auth/login` | Login and get JWT token |

### Quotes
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/quotes` | List all quotations |
| GET | `/api/quotes/:quote_no` | Get single quotation |
| POST | `/api/quotes/create` | Create new quotation |
| GET | `/api/quotes/equipment` | List equipment types |

### Health Check
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/test` | Test database connection |

## Authentication Flow

1. User enters credentials on Login Page
2. Frontend sends POST to `/api/auth/login`
3. Backend validates and returns JWT token
4. Frontend stores token in SharedPreferences
5. Token is included in Authorization header for all subsequent requests
6. Token automatically expires after 24 hours

## Testing the Connection

1. **Test Backend**: Open browser to `http://localhost:3000/api/test`
   - Should return: `{"success":true,"message":"DB Connected!","result":2}`

2. **Test Login**: Use the Flutter app login page
   - Enter username/password created during setup
   - Should redirect to Quote List page

3. **Test API Mode**: Look for "ONLINE" indicator in app bar
   - Green = Connected to API
   - Orange = Using local storage

## Troubleshooting

### Backend Issues

**Problem**: Cannot connect to MySQL
```
Error: connect ECONNREFUSED 127.0.0.1:3306
```
**Solution**: Ensure MySQL service is running:
```bash
# Windows
net start mysql

# Mac
brew services start mysql

# Linux
sudo systemctl start mysql
```

**Problem**: Access denied for user
```
Error: Access denied for user 'root'@'localhost'
```
**Solution**: Check credentials in `.env` file match your MySQL setup

### Frontend Issues

**Problem**: Network error when connecting
```
DioException [connection error]: Connection refused
```
**Solution**: 
1. Check baseUrl in `api_client.dart` matches your setup
2. For Android emulator, use `10.0.2.2` not `localhost`
3. Ensure backend server is running

**Problem**: CORS errors
```
XMLHttpRequest error
```
**Solution**: Backend already has CORS enabled. If issues persist, check:
1. Backend is running on correct port
2. No firewall blocking connections

## Development Mode

The app supports both online (API) and offline (local storage) modes:

- **When logged in**: Uses API backend, shows "ONLINE" badge
- **When logged out**: Falls back to local storage, shows "LOCAL" badge

This allows testing the UI without a running backend.

## Production Deployment

### Backend
1. Use environment variables for secrets
2. Enable HTTPS with proper SSL certificates
3. Use a process manager like PM2:
```bash
npm install -g pm2
pm2 start server.js --name "quote-api"
```

### Frontend
1. Update baseUrl to production server
2. Build release version:
```bash
flutter build apk --release      # Android
flutter build ios --release      # iOS
flutter build windows --release  # Windows
```

## Security Notes

1. Change default JWT_SECRET in production
2. Use strong passwords for database and admin accounts
3. Enable HTTPS for all API communications
4. Implement rate limiting for auth endpoints
5. Regularly update dependencies (`npm audit`, `flutter pub upgrade`)

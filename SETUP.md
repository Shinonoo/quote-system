# Quick Setup Guide

## Your Database is Ready!

You have MariaDB with existing data. Here's how to connect everything:

## 1. Update Backend Config

Edit `backend/quote-api/.env`:

```env
DB_HOST=localhost
DB_USER=root
DB_PASSWORD=YOUR_MYSQL_PASSWORD_HERE
DB_NAME=greentech_quote
PORT=3000
JWT_SECRET=any_random_string_here
```

Replace `YOUR_MYSQL_PASSWORD_HERE` with your actual MySQL root password.

## 2. Start Backend Server

```bash
cd backend/quote-api
npm install
npm run dev
```

You should see: `✅ Server running on port 3000`

## 3. Test Backend

Open browser: http://localhost:3000/api/test

Should return:
```json
{"success":true,"message":"DB Connected!","result":2}
```

## 4. Login Credentials

Use your existing users from the database:

| Username | Password | Prefix |
|----------|----------|--------|
| admin1 | (the password you set) | RCB |
| admin2 | (the password you set) | JDP |

**Note**: If you don't know the passwords, you can create a new user:

```bash
curl -X POST http://localhost:3000/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{"username":"newadmin","password":"newpassword"}'
```

## 5. Run Flutter App

```bash
cd frontend/greentech_qoute
flutter pub get
flutter run -d windows
```

## Troubleshooting

### "Connection refused" error
- Make sure MySQL is running (XAMPP/MySQL service)
- Check that backend is running on port 3000
- Verify your password in .env file

### "Access denied" error  
- Wrong MySQL password in .env file
- User doesn't have permissions

### Stuck on loading screen
- Backend not running
- Wrong API URL in Flutter code
- CORS issues

## API Endpoints Available

| Endpoint | Method | Description |
|----------|--------|-------------|
| /api/auth/login | POST | Login with username/password |
| /api/auth/register | POST | Create new user |
| /api/quotes | GET | List all quotations |
| /api/quotes/:quote_no | GET | Get single quotation |
| /api/quotes/create | POST | Create new quotation |
| /api/quotes/equipment | GET | List equipment types |
| /api/test | GET | Test database connection |

## Your Database Schema

You have these tables with data:
- **users**: 2 users (admin1, admin2)
- **equipment_types**: 11 equipment types
- **customizations**: 6 customization options
- **quotations**: 8 existing quotes
- **quotation_items**: 12 line items

Everything should work with your existing data!

import mongoose from 'mongoose';

const connectDB = async () => {
  const uri = process.env.MONGODB_URI;
  if (!uri || uri.includes('your_')) {
    console.warn('⚠️  MongoDB URI not configured. Please set MONGODB_URI in .env');
    console.warn('   Get a free cloud DB at: https://www.mongodb.com/cloud/atlas');
    return;
  }
  try {
    const conn = await mongoose.connect(uri);
    console.log(`✅ MongoDB Connected: ${conn.connection.host}`);
  } catch (error) {
    console.error(`❌ MongoDB Connection Error: ${error.message}`);
    console.error('   Make sure MongoDB is running or update MONGODB_URI in backend/.env');
    // Do NOT exit - keep the server running so other routes work
  }
};

export default connectDB;

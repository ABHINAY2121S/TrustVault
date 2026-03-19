import mongoose from 'mongoose';

const folderSchema = new mongoose.Schema({
  name: {
    type: String,
    required: true,
    trim: true,
  },
  userId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true,
  },
  color: {
    type: String,
    default: '#7c3aed', // Default purple
  },
  icon: {
    type: String,
    default: 'Folder',
  },
}, {
  timestamps: true,
});

const Folder = mongoose.model('Folder', folderSchema);

export default Folder;

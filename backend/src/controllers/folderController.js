import Folder from '../models/Folder.js';
import Document from '../models/Document.js';

// @desc    Create a new folder
// @route   POST /api/folders
// @access  Private (User)
export const createFolder = async (req, res) => {
  try {
    const { name, color, icon } = req.body;
    if (!name) return res.status(400).json({ message: 'Folder name is required' });

    const folder = await Folder.create({
      name,
      color: color || '#7c3aed',
      icon: icon || 'Folder',
      userId: req.user._id,
    });

    res.status(201).json(folder);
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: 'Server Error' });
  }
};

// @desc    Get all folders for user (with document counts)
// @route   GET /api/folders
// @access  Private (User)
export const getFolders = async (req, res) => {
  try {
    const folders = await Folder.find({ userId: req.user._id }).sort({ createdAt: -1 });

    // Get doc count for each folder
    const foldersWithCount = await Promise.all(
      folders.map(async (folder) => {
        const count = await Document.countDocuments({ folderId: folder._id, userId: req.user._id });
        return { ...folder.toObject(), documentCount: count };
      })
    );

    res.json(foldersWithCount);
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: 'Server Error' });
  }
};

// @desc    Get documents inside a specific folder
// @route   GET /api/folders/:id/documents
// @access  Private (User)
export const getFolderDocuments = async (req, res) => {
  try {
    const folder = await Folder.findOne({ _id: req.params.id, userId: req.user._id });
    if (!folder) return res.status(404).json({ message: 'Folder not found' });

    const documents = await Document.find({ folderId: folder._id, userId: req.user._id }).populate('issuerId', 'orgName');
    res.json({ folder, documents });
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: 'Server Error' });
  }
};

// @desc    Add a document to a folder
// @route   PUT /api/folders/:folderId/add/:docId
// @access  Private (User)
export const addDocToFolder = async (req, res) => {
  try {
    const folder = await Folder.findOne({ _id: req.params.folderId, userId: req.user._id });
    if (!folder) return res.status(404).json({ message: 'Folder not found' });

    const doc = await Document.findOne({ _id: req.params.docId, userId: req.user._id });
    if (!doc) return res.status(404).json({ message: 'Document not found' });

    doc.folderId = folder._id;
    await doc.save();

    res.json({ message: 'Document added to folder', document: doc });
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: 'Server Error' });
  }
};

// @desc    Remove a document from a folder
// @route   PUT /api/folders/remove/:docId
// @access  Private (User)
export const removeDocFromFolder = async (req, res) => {
  try {
    const doc = await Document.findOne({ _id: req.params.docId, userId: req.user._id });
    if (!doc) return res.status(404).json({ message: 'Document not found' });

    doc.folderId = null;
    await doc.save();

    res.json({ message: 'Document removed from folder' });
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: 'Server Error' });
  }
};

// @desc    Delete a folder (docs stay, just unlinked)
// @route   DELETE /api/folders/:id
// @access  Private (User)
export const deleteFolder = async (req, res) => {
  try {
    const folder = await Folder.findOne({ _id: req.params.id, userId: req.user._id });
    if (!folder) return res.status(404).json({ message: 'Folder not found' });

    // Unlink all documents from this folder
    await Document.updateMany({ folderId: folder._id }, { folderId: null });

    await folder.deleteOne();
    res.json({ message: 'Folder deleted successfully' });
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: 'Server Error' });
  }
};

import AccessRequest from '../models/AccessRequest.js';
import Document from '../models/Document.js';
import Folder from '../models/Folder.js';
import jwt from 'jsonwebtoken';

// @desc    Verifier requests access using a share token
// @route   POST /api/access/request
// @access  Public (Verifier calls this from web)
export const requestAccess = async (req, res) => {
  try {
    const { token, verifierName, verifierEmail } = req.body;
    if (!token) return res.status(400).json({ message: 'Token is required' });

    // Decode token to find owner and resource
    let decoded;
    try {
      decoded = jwt.verify(token, process.env.JWT_SECRET);
    } catch (e) {
      return res.status(400).json({ message: 'Invalid or expired share token' });
    }

    const resourceId = decoded.folderId || decoded.documentId;
    const resourceType = decoded.folderId ? 'folder' : 'document';

    // Find the userId from the resource
    let userId;
    if (resourceType === 'folder') {
      const folder = await Folder.findById(resourceId);
      if (!folder) return res.status(404).json({ message: 'Folder not found' });
      userId = folder.userId;
    } else {
      const doc = await Document.findById(resourceId);
      if (!doc) return res.status(404).json({ message: 'Document not found' });
      userId = doc.userId;
    }

    // Create or find existing pending request for this token
    const existing = await AccessRequest.findOne({ token, status: 'pending' });
    if (existing) {
      return res.json({ requestId: existing._id, status: 'pending', message: 'Access request already pending' });
    }

    const accessRequest = await AccessRequest.create({
      token,
      userId,
      resourceId,
      resourceType,
      verifierName: verifierName || 'A Verifier',
      verifierEmail: verifierEmail || '',
    });

    res.status(201).json({ requestId: accessRequest._id, status: 'pending' });
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: 'Server Error' });
  }
};

// @desc    User polls for their pending access requests
// @route   GET /api/access/pending
// @access  Private (User)
export const getPendingRequests = async (req, res) => {
  try {
    const requests = await AccessRequest.find({
      userId: req.user._id,
      status: 'pending',
      expiresAt: { $gt: new Date() },
    }).sort({ createdAt: -1 });

    res.json(requests);
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: 'Server Error' });
  }
};

// @desc    User approves or denies an access request
// @route   PUT /api/access/:id/respond
// @access  Private (User)
export const respondToRequest = async (req, res) => {
  try {
    const { action } = req.body; // 'approve' or 'deny'
    if (!['approve', 'deny'].includes(action)) {
      return res.status(400).json({ message: 'Action must be approve or deny' });
    }

    const request = await AccessRequest.findOne({ _id: req.params.id, userId: req.user._id });
    if (!request) return res.status(404).json({ message: 'Request not found' });

    request.status = action === 'approve' ? 'approved' : 'denied';
    await request.save();

    res.json({ message: `Request ${request.status}`, status: request.status });
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: 'Server Error' });
  }
};

// @desc    Verifier polls to check if access was approved + get resource
// @route   GET /api/access/check/:requestId
// @access  Public (Verifier polls this)
export const checkAccessStatus = async (req, res) => {
  try {
    const request = await AccessRequest.findById(req.params.requestId);
    if (!request) return res.status(404).json({ message: 'Request not found' });

    if (request.status === 'pending') return res.json({ status: 'pending' });
    if (request.status === 'denied')  return res.json({ status: 'denied', message: 'User denied access' });

    // Approved — return the full resource with all details
    let resource = null;
    if (request.resourceType === 'folder') {
      const folder = await Folder.findById(request.resourceId);
      const docs = await Document.find({ folderId: request.resourceId })
        .populate('issuerId', 'orgName orgType publicKey');
      resource = { type: 'folder', folder, documents: docs };
    } else {
      const doc = await Document.findById(request.resourceId)
        .populate('issuerId', 'orgName orgType publicKey');
      resource = { type: 'document', document: doc };
    }

    res.json({ status: 'approved', resource });
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: 'Server Error' });
  }
};


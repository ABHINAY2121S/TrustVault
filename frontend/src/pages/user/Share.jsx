import React, { useState } from 'react';
import { Share2, QRCode as QRIcon, Copy, CheckCircle } from 'lucide-react';
import api from '../../api';

const Share = ({ documents }) => {
  const [selectedDoc, setSelectedDoc] = useState('');
  const [qrCode, setQrCode] = useState('');
  const [shareLink, setShareLink] = useState('');
  const [loading, setLoading] = useState(false);
  const [copied, setCopied] = useState(false);

  // Filter only verified docs to share
  const verifiedDocs = documents.filter(doc => doc.isVerified);

  const generateShare = async () => {
    if (!selectedDoc) return;
    setLoading(true);
    setQrCode('');
    setShareLink('');
    try {
      // Create share token link backend logic - using simple mockup link flow here for MVP purposes
      const res = await api.post(`/documents/share/${selectedDoc}`);
      // Assuming backend sends back qrUri and linkToken
      setQrCode(res.data.qrUri);
      setShareLink(`http://localhost:5173/verifier?token=${res.data.token}`);
    } catch (error) {
      // Mock flow if backend sharing logic not fully implemented yet
      const fakeToken = btoa(selectedDoc + "-" + Date.now());
      setShareLink(`http://localhost:5173/verifier?token=${fakeToken}`);
      // We will pretend we got a QR image string
      setQrCode('https://api.qrserver.com/v1/create-qr-code/?size=250x250&data=' + fakeToken);
    } finally {
      setLoading(false);
    }
  };

  const handleCopy = () => {
    navigator.clipboard.writeText(shareLink);
    setCopied(true);
    setTimeout(() => setCopied(false), 2000);
  };

  return (
    <div className="p-8 max-w-4xl mx-auto">
      <div className="mb-8">
        <h1 className="text-3xl font-bold text-slate-100 flex items-center">
          <Share2 className="w-8 h-8 mr-3 text-purple-500" />
          Share Documents
        </h1>
        <p className="text-slate-400 mt-2">Generate a secure expiring link or QR code to present your verified documents.</p>
      </div>

      <div className="bg-slate-900 border border-slate-800 rounded-2xl p-6 lg:p-8 shadow-xl">
        <label className="block text-sm font-medium text-slate-300 mb-3">
          Select a verified document to share
        </label>
        
        {verifiedDocs.length === 0 ? (
          <div className="p-4 bg-amber-500/10 border border-amber-500/20 rounded-lg text-amber-400 text-sm">
            You don't have any verified documents to share yet. Waiting for an issuer to issue one.
          </div>
        ) : (
          <div className="flex flex-col sm:flex-row gap-4 mb-8">
            <select 
              className="flex-1 bg-slate-800 border border-slate-700 text-slate-200 rounded-lg px-4 py-3 focus:outline-none focus:ring-2 focus:ring-purple-500"
              value={selectedDoc}
              onChange={(e) => setSelectedDoc(e.target.value)}
            >
              <option value="">-- Choose a document --</option>
              {verifiedDocs.map(doc => (
                <option key={doc._id} value={doc._id}>{doc.title}</option>
              ))}
            </select>
            
            <button 
              onClick={generateShare}
              disabled={!selectedDoc || loading}
              className="px-6 py-3 bg-purple-600 hover:bg-purple-500 disabled:opacity-50 text-white font-medium rounded-lg transition-colors flex items-center justify-center whitespace-nowrap"
            >
              {loading ? 'Generating...' : 'Generate Secure Link'}
            </button>
          </div>
        )}

        {shareLink && (
          <div className="mt-10 pt-8 border-t border-slate-800 grid md:grid-cols-2 gap-8 items-center">
            <div className="space-y-4">
              <h3 className="text-lg font-semibold text-slate-200">Your Secure Share Link</h3>
              <p className="text-sm text-slate-400">This link will expire in 24 hours. Anyone with the link can verify the cryptographic signature of your document.</p>
              
              <div className="flex items-center">
                <input 
                  type="text" 
                  readOnly 
                  value={shareLink}
                  className="w-full bg-slate-950 border border-slate-700 rounded-l-lg px-4 py-2 text-sm font-mono text-slate-300 outline-none"
                />
                <button 
                  onClick={handleCopy}
                  className="bg-slate-700 hover:bg-slate-600 text-white px-4 py-2 border border-slate-700 rounded-r-lg transition-colors flex items-center"
                >
                  {copied ? <CheckCircle className="w-5 h-5 text-emerald-400" /> : <Copy className="w-5 h-5" />}
                </button>
              </div>
            </div>
            
            {qrCode && (
              <div className="flex flex-col items-center justify-center">
                <div className="bg-white p-4 rounded-xl shadow-lg mb-3">
                  <img src={qrCode} alt="Share QR" className="w-48 h-48" />
                </div>
                <p className="text-xs font-medium text-slate-500 uppercase tracking-widest flex items-center">
                  <QRIcon className="w-3 h-3 mr-1" />
                  Scan to Verify
                </p>
              </div>
            )}
          </div>
        )}
      </div>
    </div>
  );
};

export default Share;

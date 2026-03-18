import React, { useState, useEffect, useRef } from 'react';
import { ScanLine, Link as LinkIcon, ShieldCheck, AlertTriangle, Loader2, XCircle } from 'lucide-react';
import { Html5QrcodeScanner } from 'html5-qrcode';
import api from '../../api';

const Verify = () => {
  const [activeTab, setActiveTab] = useState('link'); // 'link' or 'qr'
  const [tokenInput, setTokenInput] = useState('');
  const [loading, setLoading] = useState(false);
  const [result, setResult] = useState(null);
  const [error, setError] = useState('');
  
  // Try to grab token from URL if somebody clicked a share link directly
  useEffect(() => {
    const params = new URLSearchParams(window.location.search);
    const tokenFromUrl = params.get('token');
    if (tokenFromUrl) {
      setTokenInput(tokenFromUrl);
      verifyToken(tokenFromUrl);
    }
  }, []);

  const verifyToken = async (tokenToVerify) => {
    if (!tokenToVerify) return;
    setLoading(true);
    setError('');
    setResult(null);
    try {
      const res = await api.get(`/verify/${tokenToVerify}`);
      setResult(res.data);
    } catch (err) {
       setError(err.response?.data?.message || 'Verification failed. Document may be tampered or link expired.');
    } finally {
      setLoading(false);
    }
  };

  const handleManualSubmit = (e) => {
    e.preventDefault();
    verifyToken(tokenInput);
  };

  // QR Scanner initialization
  useEffect(() => {
    let html5QrcodeScanner;
    if (activeTab === 'qr' && !result && !loading) {
      html5QrcodeScanner = new Html5QrcodeScanner(
        "qr-reader",
        { fps: 10, qrbox: {width: 250, height: 250} },
        /* verbose= */ false
      );
      html5QrcodeScanner.render((decodedText) => {
        // Stop scanning, assume decoded text is the token
        html5QrcodeScanner.clear();
        setTokenInput(decodedText);
        verifyToken(decodedText);
      }, (err) => {
        // ignore scan errors
      });
    }

    return () => {
      if (html5QrcodeScanner) {
        html5QrcodeScanner.clear().catch(e => console.error(e));
      }
    };
  }, [activeTab, result, loading]);

  const resetScanner = () => {
    setResult(null);
    setError('');
    setTokenInput('');
  };

  return (
    <div className="p-8 max-w-4xl mx-auto">
      <div className="mb-8">
        <h1 className="text-3xl font-bold text-slate-100 flex items-center">
          <ScanLine className="w-8 h-8 mr-3 text-indigo-500" />
          Verify Document
        </h1>
        <p className="text-slate-400 mt-2">Check the cryptographic integrity and authenticity of a provided document or bundle.</p>
      </div>

      <div className="bg-slate-900 border border-slate-800 rounded-2xl shadow-xl overflow-hidden">
        
        {/* Tabs */}
        {!result && !loading && (
          <div className="flex border-b border-slate-800">
            <button 
              onClick={() => setActiveTab('link')} 
              className={`flex-1 py-4 text-sm font-medium transition-colors flex justify-center items-center ${activeTab === 'link' ? 'bg-indigo-600/10 text-indigo-400 border-b-2 border-indigo-500' : 'text-slate-400 hover:text-slate-300'}`}
            >
              <LinkIcon className="w-4 h-4 mr-2" /> Manual Token / Link
            </button>
            <button 
              onClick={() => setActiveTab('qr')} 
              className={`flex-1 py-4 text-sm font-medium transition-colors flex justify-center items-center ${activeTab === 'qr' ? 'bg-indigo-600/10 text-indigo-400 border-b-2 border-indigo-500' : 'text-slate-400 hover:text-slate-300'}`}
            >
              <ScanLine className="w-4 h-4 mr-2" /> Scan QR Code
            </button>
          </div>
        )}

        <div className="p-8">
          {loading && (
            <div className="py-16 text-center">
              <Loader2 className="w-12 h-12 text-indigo-500 animate-spin mx-auto mb-4" />
              <h3 className="text-xl font-medium text-slate-200">Verifying Cryptographic Signature...</h3>
              <p className="text-slate-400 mt-2">Checking blockchain/database records for document integrity.</p>
            </div>
          )}

          {!loading && !result && activeTab === 'link' && (
            <form onSubmit={handleManualSubmit} className="max-w-xl mx-auto py-8">
              <label className="block text-sm font-medium text-slate-300 mb-3 text-center">
                Paste the verification token or full share link below
              </label>
              <div className="flex flex-col sm:flex-row gap-3">
                <input 
                  type="text" 
                  value={tokenInput}
                  onChange={(e) => setTokenInput(e.target.value)}
                  placeholder="Paste token here..." 
                  required
                  className="flex-1 bg-slate-950 border border-slate-700 rounded-xl px-4 py-3 text-slate-200 focus:ring-1 focus:ring-indigo-500 outline-none"
                />
                <button type="submit" className="px-6 py-3 bg-indigo-600 hover:bg-indigo-500 text-white rounded-xl font-medium transition-colors">
                  Verify
                </button>
              </div>
              
              {error && (
                <div className="mt-6 p-4 bg-red-500/10 border border-red-500/50 rounded-lg text-red-400 text-center flex flex-col items-center">
                  <XCircle className="w-8 h-8 mb-2" />
                  <span className="font-semibold text-lg mb-1">Verification Failed</span>
                  <span className="text-sm">{error}</span>
                </div>
              )}
            </form>
          )}

          {!loading && !result && activeTab === 'qr' && (
            <div className="max-w-md mx-auto py-4">
              <div id="qr-reader" className="w-full bg-slate-950 rounded-xl overflow-hidden border border-slate-700"></div>
              {error && (
                <div className="mt-6 p-4 bg-red-500/10 border border-red-500/50 rounded-lg text-red-400 text-center">
                  {error}
                </div>
              )}
            </div>
          )}

          {/* SUCCESS RESULT VIEW */}
          {result && (
            <div className="max-w-2xl mx-auto">
              <div className="bg-emerald-500/10 border border-emerald-500/30 rounded-2xl p-6 text-center mb-8 relative overflow-hidden">
                <div className="absolute top-0 right-0 w-32 h-32 bg-emerald-500/20 rounded-full blur-3xl -mr-10 -mt-10"></div>
                <ShieldCheck className="w-16 h-16 text-emerald-500 mx-auto mb-4" />
                <h2 className="text-2xl font-bold text-emerald-400 mb-2">Cryptographically Verified</h2>
                <p className="text-emerald-500/80 text-sm">
                  Document integrity intact. Timestamp: {new Date(result.verifiedAt).toLocaleString()}
                </p>
              </div>

              <div className="bg-slate-950 border border-slate-800 rounded-xl p-6 mb-8">
                <h3 className="text-lg font-semibold text-slate-200 mb-4 pb-4 border-b border-slate-800">Document Details</h3>
                
                <div className="grid grid-cols-2 gap-y-4 gap-x-8 text-sm">
                  <div>
                    <span className="block text-slate-500 mb-1">Title</span>
                    <span className="font-medium text-slate-200">{result.document.title}</span>
                  </div>
                  <div>
                    <span className="block text-slate-500 mb-1">Category</span>
                    <span className="font-medium text-slate-200">{result.document.category}</span>
                  </div>
                  <div>
                    <span className="block text-slate-500 mb-1">Issued By</span>
                    <span className="font-medium text-slate-200">{result.document.issuerId?.orgName || 'Self Uploaded'}</span>
                  </div>
                  <div>
                    <span className="block text-slate-500 mb-1">Expiry Date</span>
                    <span className="font-medium text-slate-200">
                      {result.document.expiryDate ? new Date(result.document.expiryDate).toLocaleDateString() : 'Lifetime'}
                    </span>
                  </div>
                </div>

                {result.document.metadata && Object.keys(result.document.metadata).length > 0 && (
                  <div className="mt-6 pt-6 border-t border-slate-800">
                    <span className="block text-slate-500 mb-3 text-sm">Extracted Metadata</span>
                    <div className="grid grid-cols-2 gap-4 text-sm">
                       {/* Handle metadata if mapped properly, else fallback */}
                       <div className="bg-slate-900 px-4 py-3 rounded-lg border border-slate-800 col-span-2">
                         <pre className="text-slate-300 font-mono text-xs whitespace-pre-wrap">
                           {JSON.stringify(result.document.metadata, null, 2)}
                         </pre>
                       </div>
                    </div>
                  </div>
                )}
              </div>

              <div className="text-center">
                <button onClick={resetScanner} className="text-indigo-400 hover:text-indigo-300 font-medium text-sm transition-colors">
                  Verify Another Document
                </button>
              </div>
            </div>
          )}
        </div>
      </div>
    </div>
  );
};

export default Verify;


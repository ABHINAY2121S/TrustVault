import React from 'react';
import { Database, DownloadCloud } from 'lucide-react';

const Records = ({ records, loading }) => {
  return (
    <div className="p-8 max-w-6xl mx-auto">
      <div className="mb-8">
        <h1 className="text-3xl font-bold text-slate-100 flex items-center">
          <Database className="w-8 h-8 mr-3 text-emerald-500" />
          Issued Records
        </h1>
        <p className="text-slate-400 mt-2">View all documents cryptographically signed and issued by your organization.</p>
      </div>

      <div className="bg-slate-900 border border-slate-800 rounded-2xl shadow-xl overflow-hidden">
        <div className="overflow-x-auto">
          <table className="w-full text-left text-sm text-slate-400">
            <thead className="bg-slate-950/50 text-xs uppercase text-slate-500 border-b border-slate-800">
              <tr>
                <th className="px-6 py-4 font-medium tracking-wider">Document Title</th>
                <th className="px-6 py-4 font-medium tracking-wider">Category</th>
                <th className="px-6 py-4 font-medium tracking-wider">Recipient (User)</th>
                <th className="px-6 py-4 font-medium tracking-wider">Date Issued</th>
                <th className="px-6 py-4 font-medium tracking-wider">Status</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-slate-800/50">
              {loading ? (
                <tr>
                  <td colSpan="5" className="px-6 py-8 text-center">Loading records...</td>
                </tr>
              ) : records.length === 0 ? (
                <tr>
                  <td colSpan="5" className="px-6 py-16 text-center">
                    <DownloadCloud className="w-12 h-12 text-slate-600 mx-auto mb-3" />
                    <p className="text-slate-400 text-lg">No documents issued yet.</p>
                  </td>
                </tr>
              ) : (
                records.map((doc) => (
                  <tr key={doc._id} className="hover:bg-slate-800/30 transition-colors">
                    <td className="px-6 py-4 font-medium text-slate-200">{doc.title}</td>
                    <td className="px-6 py-4">{doc.category}</td>
                    <td className="px-6 py-4 text-slate-300">{doc.userId?.email || 'Unknown User'}</td>
                    <td className="px-6 py-4">
                      {new Date(doc.createdAt).toLocaleDateString()}
                    </td>
                    <td className="px-6 py-4">
                      <span className="px-2.5 py-1 text-xs font-medium rounded-full bg-emerald-500/10 text-emerald-400 border border-emerald-500/20">
                        Crypto-Signed
                      </span>
                    </td>
                  </tr>
                ))
              )}
            </tbody>
          </table>
        </div>
      </div>
    </div>
  );
};

export default Records;

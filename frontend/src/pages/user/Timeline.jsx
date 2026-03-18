import React from 'react';
import { Calendar, CircleDot } from 'lucide-react';

const Timeline = ({ documents }) => {
  // Sort docs by creation date desc
  const sortedDocs = [...documents].sort((a, b) => new Date(b.createdAt) - new Date(a.createdAt));

  return (
    <div className="p-8 max-w-4xl mx-auto">
      <div className="mb-8">
        <h1 className="text-3xl font-bold text-slate-100 flex items-center">
          <Calendar className="w-8 h-8 mr-3 text-purple-500" />
          Document Timeline
        </h1>
        <p className="text-slate-400 mt-2">A chronological history of your added and issued documents.</p>
      </div>

      <div className="relative border-l border-slate-700 ml-4 space-y-8 mt-10">
        {sortedDocs.map((doc, index) => (
          <div key={doc._id} className="relative pl-8">
            <span className="absolute -left-[11px] top-2 bg-slate-950 p-0.5">
              <CircleDot className={`w-5 h-5 ${doc.isVerified ? 'text-emerald-500' : 'text-amber-500'}`} />
            </span>
            <div className="bg-slate-900 border border-slate-800 rounded-xl p-5 shadow-lg">
              <div className="flex justify-between items-start mb-2">
                <h3 className="text-lg font-semibold text-slate-200">{doc.title}</h3>
                <span className="text-xs font-medium text-slate-400 bg-slate-800 px-2.5 py-1 rounded-md">
                  {new Date(doc.createdAt).toLocaleDateString(undefined, {
                    year: 'numeric',
                    month: 'short',
                    day: 'numeric'
                  })}
                </span>
              </div>
              <p className="text-sm text-slate-500">{doc.category}</p>
              {doc.issuerId && (
                <div className="mt-4 pt-4 border-t border-slate-800 text-sm text-slate-400">
                  Digitally issued by <span className="text-slate-200 font-medium">{doc.issuerId.orgName}</span>
                </div>
              )}
            </div>
          </div>
        ))}
        {sortedDocs.length === 0 && (
          <p className="text-slate-500 pl-8">No documents to show on the timeline yet.</p>
        )}
      </div>
    </div>
  );
};

export default Timeline;

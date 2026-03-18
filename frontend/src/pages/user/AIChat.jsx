import React, { useState, useRef, useEffect } from 'react';
import { Bot, Send, User as UserIcon, Loader2 } from 'lucide-react';
import api from '../../api';

const AIChat = ({ documents }) => {
  const [messages, setMessages] = useState([
    { role: 'assistant', content: 'Hello! I am your TrustVault document assistant. I have secure access to the metadata of your verified documents. How can I help you today?' }
  ]);
  const [input, setInput] = useState('');
  const [loading, setLoading] = useState(false);
  const messagesEndRef = useRef(null);

  const scrollToBottom = () => {
    messagesEndRef.current?.scrollIntoView({ behavior: 'smooth' });
  };

  useEffect(() => {
    scrollToBottom();
  }, [messages]);

  const handleSubmit = async (e) => {
    e.preventDefault();
    if (!input.trim()) return;

    const userMessage = { role: 'user', content: input };
    setMessages(prev => [...prev, userMessage]);
    setInput('');
    setLoading(true);

    try {
      const res = await api.post('/ai/query', { question: userMessage.content });
      setMessages(prev => [...prev, { role: 'assistant', content: res.data.reply }]);
    } catch (error) {
      console.error(error);
      setMessages(prev => [...prev, { role: 'assistant', content: 'Sorry, I encountered an error connecting to the AI service. Please ensure the backend is running and the GitHub token is valid.' }]);
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="p-8 max-w-5xl mx-auto h-full flex flex-col">
      <div className="mb-6">
        <h1 className="text-3xl font-bold text-slate-100 flex items-center">
          <Bot className="w-8 h-8 mr-3 text-purple-500" />
          AI Document Assistant
        </h1>
        <p className="text-slate-400 mt-2">Powered by GitHub Models (GPT-4o). Ask questions about the contents and metadata of your verified documents.</p>
      </div>

      <div className="flex-1 bg-slate-900 border border-slate-800 rounded-2xl shadow-xl flex flex-col overflow-hidden relative">
        {/* Chat Area */}
        <div className="flex-1 overflow-y-auto p-6 space-y-6">
          {messages.map((msg, idx) => (
            <div key={idx} className={`flex ${msg.role === 'user' ? 'justify-end' : 'justify-start'}`}>
              <div className={`flex max-w-[80%] ${msg.role === 'user' ? 'flex-row-reverse' : 'flex-row'}`}>
                <div className={`w-8 h-8 rounded-full flex items-center justify-center shrink-0 ${
                  msg.role === 'user' ? 'bg-indigo-600 ml-3' : 'bg-purple-600 mr-3'
                }`}>
                  {msg.role === 'user' ? <UserIcon className="w-4 h-4 text-white" /> : <Bot className="w-4 h-4 text-white" />}
                </div>
                <div className={`py-3 px-4 rounded-2xl ${
                  msg.role === 'user' 
                    ? 'bg-indigo-600/10 border border-indigo-500/20 text-indigo-100 rounded-tr-sm' 
                    : 'bg-slate-800 border border-slate-700 text-slate-300 rounded-tl-sm'
                }`}>
                  <p className="whitespace-pre-wrap leading-relaxed">{msg.content}</p>
                </div>
              </div>
            </div>
          ))}
          {loading && (
            <div className="flex justify-start">
              <div className="flex flex-row">
                <div className="w-8 h-8 bg-purple-600 mr-3 rounded-full flex items-center justify-center shrink-0">
                  <Bot className="w-4 h-4 text-white" />
                </div>
                <div className="py-3 px-5 rounded-2xl bg-slate-800 border border-slate-700 rounded-tl-sm flex items-center">
                  <Loader2 className="w-5 h-5 text-purple-400 animate-spin" />
                  <span className="ml-2 text-slate-400 text-sm">Thinking...</span>
                </div>
              </div>
            </div>
          )}
          <div ref={messagesEndRef} />
        </div>

        {/* Input Area */}
        <div className="p-4 bg-slate-950/50 border-t border-slate-800">
          <form onSubmit={handleSubmit} className="flex gap-3">
            <input
              type="text"
              value={input}
              onChange={(e) => setInput(e.target.value)}
              placeholder="e.g. When does my Aadhaar card expire?"
              className="flex-1 bg-slate-900 border border-slate-700 rounded-xl px-5 py-3 text-slate-200 focus:outline-none focus:border-purple-500 focus:ring-1 focus:ring-purple-500 transition-all"
              disabled={loading}
            />
            <button
              type="submit"
              disabled={loading || !input.trim()}
              className="bg-purple-600 hover:bg-purple-500 disabled:opacity-50 text-white p-3 rounded-xl transition-colors flex items-center justify-center group"
            >
              <Send className="w-5 h-5 group-hover:-translate-y-0.5 group-hover:translate-x-0.5 transition-transform" />
            </button>
          </form>
        </div>
      </div>
    </div>
  );
};

export default AIChat;

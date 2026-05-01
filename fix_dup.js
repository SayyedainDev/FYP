const fs = require('fs');
let s = fs.readFileSync('fy_dental_backend/server.js', 'utf8');
const dup = " CRITICAL RULES - You must follow these without exception:\\n- Do NOT generate questions about page numbers, chapter numbers, or table of contents\\n- Do NOT ask 'What is on page X?' or 'What chapter is Y?'\\n- Do NOT reference any page numbers or chapter numbers in your questions\\n- ONLY generate questions about actual concepts, facts, definitions, techniques, processes, or knowledge from the content\\n- Every question must test understanding of a concept, not memory of a location\\n- If the context only contains table of contents or index, say ERROR:TOC_ONLY and do not generate questions";
s = s.replace(dup + dup, dup);
fs.writeFileSync('fy_dental_backend/server.js', s);

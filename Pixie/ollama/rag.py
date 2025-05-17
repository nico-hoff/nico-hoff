from langchain_community.llms import Ollama
from langchain_community.vectorstores import FAISS
from langchain.embeddings import HuggingFaceEmbeddings
from langchain.text_splitter import CharacterTextSplitter
from langchain_community.document_loaders import TextLoader
from langchain.chains import RetrievalQA

# 1. LLM: Ollama lokal (z. B. llama3)
llm = Ollama(model="tinyllama:1.1b-chat-v0.6-q2_K")

# 2. Dokumente laden
loader = TextLoader("docs/story.txt")
docs = loader.load()

# 3. Dokumente aufteilen
text_splitter = CharacterTextSplitter(chunk_size=500, chunk_overlap=50)
documents = text_splitter.split_documents(docs)

# 4. Embeddings (HuggingFace lokal)
embeddings = HuggingFaceEmbeddings(model_name="sentence-transformers/all-MiniLM-L6-v2")

# 5. Vektor-DB: FAISS lokal aufbauen
vectorstore = FAISS.from_documents(documents, embeddings)

# 6. Retriever bauen
retriever = vectorstore.as_retriever()

# 7. RAG-Chain mit Ollama und FAISS
rag_chain = RetrievalQA.from_chain_type(
    llm=llm,
    retriever=retriever,
    return_source_documents=True
)

# 8. Beispiel-Frage
query = "um wen geht es in der story?"
result = rag_chain.invoke(query)

print("Antwort:")
print(result["result"])
print("\nVerwendete Quelle(n):")
for doc in result["source_documents"]:
    print("-", doc.metadata.get("source", "Unbekannt"))

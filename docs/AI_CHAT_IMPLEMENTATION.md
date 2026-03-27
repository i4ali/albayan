# AI Chat Feature Implementation Plan
**AlBayan App - Islamic Quranic Commentary Assistant**

---

## 📐 Architecture Overview

```
┌─────────────────────────────────────────────────────────────┐
│                     USER INTERFACE                           │
├─────────────────────────────────────────────────────────────┤
│  1. Floating Chat Button (bottom-right)                     │
│  2. Full-Screen Chat View                                   │
│  3. Message List (ScrollView)                               │
│  4. Input Bar (text field + send button)                    │
│  5. Suggested Questions (initial state)                     │
└─────────────────────────────────────────────────────────────┘
                          ↓
┌─────────────────────────────────────────────────────────────┐
│                   CHAT MANAGER (State)                       │
├─────────────────────────────────────────────────────────────┤
│  • Message history (local + persistent)                     │
│  • Loading states                                           │
│  • Error handling                                           │
│  • Rate limiting (free vs premium)                          │
└─────────────────────────────────────────────────────────────┘
                          ↓
┌─────────────────────────────────────────────────────────────┐
│                    QUERY PROCESSOR                           │
├─────────────────────────────────────────────────────────────┤
│  Step 1: Analyze user question                              │
│  Step 2: Search local knowledge (RAG Service)               │
│  Step 3: Check confidence score                             │
│  Step 4: If score < 0.7 → OpenRouter LLM                    │
└─────────────────────────────────────────────────────────────┘
      ↓                                    ↓
┌──────────────────┐              ┌──────────────────────┐
│   RAG SERVICE    │              │  OPENROUTER SERVICE  │
├──────────────────┤              ├──────────────────────┤
│ • Vector search  │              │ • API integration    │
│ • Embeddings     │              │ • Context injection  │
│ • Similarity     │              │ • Response parsing   │
│ • Citation       │              │ • Error handling     │
└──────────────────┘              └──────────────────────┘
      ↓                                    ↓
┌─────────────────────────────────────────────────────────────┐
│                    DATA SOURCES                              │
├─────────────────────────────────────────────────────────────┤
│  • Tafsir JSON files (all 5 layers + summaries)            │
│  • Quran text (Arabic + English translations)               │
│  • Surah metadata (names, revelation type, verse counts)    │
└─────────────────────────────────────────────────────────────┘
```

---

## 🎨 ASCII Wireframes

### 1. Main Screen with Floating Chat Button
```
┌─────────────────────────────────────────┐
│  [👤] 🌙 Assalamu Alaikum     [🔥3][❤️8]│
│                                          │
│  Explore the Quran                       │
│  ┌────────────────────────────────────┐ │
│  │ 🔍 Search surahs...                │ │
│  └────────────────────────────────────┘ │
│                                          │
│  ┌──────┐ ┌──────┐ ┌──────┐            │
│  │ 114  │ │ 6236 │ │  5   │            │
│  │Surahs│ │Verses│ │Layers│            │
│  └──────┘ └──────┘ └──────┘            │
│                                          │
│  ┌────────────────────────────────────┐ │
│  │ 1  Al-Fatiha        الفاتحة      │ │
│  │    The Opening                     │ │
│  │    📖 7 verses  📍 Meccan          │ │
│  └────────────────────────────────────┘ │
│  ┌────────────────────────────────────┐ │
│  │ 2  Al-Baqarah      البقرة        │ │
│  │    The Cow                         │ │
│  │    📖 286 verses  📍 Medinan       │ │
│  └────────────────────────────────────┘ │
│                                          │
│                                          │
│                                          │
│                            ┌──────────┐  │
│                            │    ✨    │  │← FLOATING
│                            │   💬     │  │  CHAT BUTTON
│                            └──────────┘  │  (animated pulse)
└─────────────────────────────────────────┘
```

### 2. Full-Screen Chat View (Initial State)
```
┌─────────────────────────────────────────┐
│ ← Back            Ask About Islam    [⚙]│← Navigation bar
│━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━│
│                                          │
│              ┌────────────┐              │
│              │     ✨     │              │
│              │    💬      │              │← Bot avatar
│              └────────────┘              │
│                                          │
│  Assalamu Alaikum! 🌙                   │
│  I'm your Islamic knowledge assistant.   │
│                                          │
│  Ask me anything about:                  │
│  • Quran verses & tafsir                │
│  • Shia Islamic teachings               │
│  • Ahlul Bayt perspectives              │
│  • Comparative analysis                 │
│                                          │
│  💡 Suggested questions:                 │
│                                          │
│  ┌────────────────────────────────────┐ │
│  │ 📖 What is the meaning of Surah 1? │ │← Quick action
│  └────────────────────────────────────┘ │  (tappable)
│  ┌────────────────────────────────────┐ │
│  │ ⭐ Explain Ayat al-Kursi            │ │
│  └────────────────────────────────────┘ │
│  ┌────────────────────────────────────┐ │
│  │ 🕌 Ahlul Bayt view on charity      │ │
│  └────────────────────────────────────┘ │
│  ┌────────────────────────────────────┐ │
│  │ ⚖️  Compare Shia vs Sunni prayer    │ │
│  └────────────────────────────────────┘ │
│                                          │
│  Spacer ↓                                │
│                                          │
│━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━│
│ ┌──────────────────────────────┐ [📤] │← Input bar
│ │ Type your question...        │  ↑   │  (always visible)
│ └──────────────────────────────┘ Send │
└─────────────────────────────────────────┘
```

### 3. Chat Conversation (Active)
```
┌─────────────────────────────────────────┐
│ ← Back            Ask About Islam    [⚙]│
│━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━│
│                                          │
│  ┌────────────────────────────────────┐ │
│  │ Hi! I'm your Quran assistant. 🌙   │ │← BOT MESSAGE
│  │ Ask me about Islamic teachings.    │ │  (left-aligned)
│  │ 🕐 2:30 PM                          │ │  (glass effect)
│  └────────────────────────────────────┘ │
│                                          │
│       ┌──────────────────────────────┐  │
│       │ What does Surah Al-Fatiha   │  │← USER MESSAGE
│       │ teach us?                    │  │  (right-aligned)
│       │                     🕐 2:31 PM│  │  (gradient bg)
│       └──────────────────────────────┘  │
│                                          │
│  ┌────────────────────────────────────┐ │
│  │ 📚 Great question! Let me help...  │ │← BOT RESPONSE
│  │                                    │ │  (RAG-based)
│  │ According to our tafsir library:   │ │
│  │                                    │ │
│  │ **Surah Al-Fatiha teaches:**      │ │
│  │ • Divine mercy and compassion      │ │
│  │ • The straight path (Sirat)        │ │
│  │ • Worship & seeking Allah's help   │ │
│  │ • Gratitude to the Sustainer       │ │
│  │                                    │ │
│  │ ┌────────────────────────────────┐│ │← SOURCE CARD
│  │ │📖 Source: Foundation Layer     ││ │  (interactive)
│  │ │📍 Surah 1: Al-Fatiha           ││ │
│  │ │🔗 [View Full Tafsir →]         ││ │
│  │ └────────────────────────────────┘│ │
│  │                                    │ │
│  │ Would you like to explore specific │ │
│  │ verses or layers?     🕐 2:31 PM  │ │
│  └────────────────────────────────────┘ │
│                                          │
│       ┌──────────────────────────────┐  │
│       │ Tell me about verse 1:6     │  │← USER
│       │                     🕐 2:32 PM│  │
│       └──────────────────────────────┘  │
│                                          │
│  ┌────────────────────────────────────┐ │
│  │ ⏳ Searching knowledge base...     │ │← LOADING
│  │ 🕐 2:32 PM                          │ │  (animated dots)
│  └────────────────────────────────────┘ │
│                                          │
│━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━│
│ ┌──────────────────────────────┐ [📤] │
│ │ Type your question...        │      │
│ └──────────────────────────────┘      │
└─────────────────────────────────────────┘
```

### 4. Settings/Options Menu

#### 4a. Free User (0-2 messages used)
```
┌─────────────────────────────────────────┐
│ ← Back            Chat Settings      [✕]│
│━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━│
│                                          │
│  💬 Chat Access                          │
│  ┌────────────────────────────────────┐ │
│  │ Status: Free User                  │ │
│  │ Messages Used: 1 / 2               │ │
│  │                                    │ │
│  │ Want unlimited chat?               │ │
│  │ [Subscribe for $4.99/mo] 🌟       │ │
│  │ [Buy Tafsir for $2.99] 📖         │ │
│  └────────────────────────────────────┘ │
│                                          │
│  🎨 Appearance                           │
│  ┌────────────────────────────────────┐ │
│  │ Theme: Auto (matches app theme)    │ │
│  └────────────────────────────────────┘ │
│                                          │
│  🗑️ Data                                 │
│  ┌────────────────────────────────────┐ │
│  │ [Clear Conversation History]       │ │
│  └────────────────────────────────────┘ │
│                                          │
└─────────────────────────────────────────┘
```

#### 4b. One-time Purchase User
```
┌─────────────────────────────────────────┐
│ ← Back            Chat Settings      [✕]│
│━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━│
│                                          │
│  💬 Chat Access                          │
│  ┌────────────────────────────────────┐ │
│  │ Status: Tafsir Owner               │ │
│  │ ✅ All 114 surahs unlocked         │ │
│  │ ❌ AI Chat not available           │ │
│  │                                    │ │
│  │ Want unlimited AI chat?            │ │
│  │ [Subscribe for $4.99/mo] 💬✨     │ │
│  │ Keep your lifetime tafsir access!  │ │
│  └────────────────────────────────────┘ │
│                                          │
│  🎨 Appearance                           │
│  ┌────────────────────────────────────┐ │
│  │ Theme: Auto (matches app theme)    │ │
│  └────────────────────────────────────┘ │
│                                          │
└─────────────────────────────────────────┘
```

#### 4c. Subscription User
```
┌─────────────────────────────────────────┐
│ ← Back            Chat Settings      [✕]│
│━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━│
│                                          │
│  💬 Subscription Status                  │
│  ┌────────────────────────────────────┐ │
│  │ Status: Premium Subscriber ✨      │ │
│  │ Plan: $4.99/month                  │ │
│  │ Renews: December 9, 2025           │ │
│  │                                    │ │
│  │ [Manage Subscription] →            │ │
│  └────────────────────────────────────┘ │
│                                          │
│  🧠 AI Behavior                          │
│  ┌────────────────────────────────────┐ │
│  │ ☑ Prioritize local knowledge (RAG)│ │
│  │ ☑ Include source citations        │ │
│  │ ☑ Use LLM for complex questions   │ │
│  └────────────────────────────────────┘ │
│                                          │
│  📊 Usage This Month                     │
│  ┌────────────────────────────────────┐ │
│  │ Questions: 47 (Unlimited)          │ │
│  │ RAG Responses: 38 (81%)            │ │
│  │ LLM Responses: 9 (19%)             │ │
│  └────────────────────────────────────┘ │
│                                          │
│  🗑️ Data                                 │
│  ┌────────────────────────────────────┐ │
│  │ [Clear Conversation History]       │ │
│  │ [Download Chat Log]                │ │
│  └────────────────────────────────────┘ │
│                                          │
└─────────────────────────────────────────┘
```

---

## 🏗️ Component Structure

### New Files to Create

```
AlBayan/
├── Models/
│   └── ChatModels.swift              ← NEW
│       • ChatMessage
│       • MessageSource (user/bot/system)
│       • MessageMetadata (source type, confidence, references)
│       • QuestionCategory (tafsir, verse, general, etc.)
│       • SearchResult
│
├── Services/
│   ├── ChatManager.swift             ← NEW
│   │   • @MainActor ObservableObject
│   │   • Message history management
│   │   • Query orchestration (RAG → LLM)
│   │   • Conversation persistence
│   │   • Rate limiting logic
│   │
│   ├── RAGService.swift               ← NEW
│   │   • Knowledge base indexing
│   │   • Keyword extraction
│   │   • Similarity scoring
│   │   • Context extraction from tafsir
│   │   • Citation generation
│   │
│   ├── OpenRouterService.swift        ← NEW
│   │   • API client (URLSession)
│   │   • Request/response models
│   │   • Prompt engineering
│   │   • Streaming support (future)
│   │   • Error handling & retries
│   │
│   └── EmbeddingService.swift         ← NEW (Optional - Phase 2)
│       • Local embeddings (CoreML)
│       • OR API-based embeddings (OpenAI)
│       • Vector similarity calculations
│
└── Views/
    ├── Chat/
    │   ├── ChatFloatingButton.swift   ← NEW
    │   │   • Animated button
    │   │   • Badge for unread (future)
    │   │   • Theme-adaptive styling
    │   │
    │   ├── ChatView.swift              ← NEW
    │   │   • Full-screen container
    │   │   • Navigation bar
    │   │   • Message list
    │   │   • Input bar integration
    │   │
    │   ├── ChatMessageList.swift       ← NEW
    │   │   • ScrollViewReader
    │   │   • Auto-scroll to bottom
    │   │   • Loading indicator
    │   │
    │   ├── MessageBubble.swift         ← NEW
    │   │   • User vs Bot styling
    │   │   • Markdown support (future)
    │   │   • Source citation cards
    │   │
    │   ├── ChatInputBar.swift          ← NEW
    │   │   • Text field
    │   │   • Send button
    │   │   • Character limit
    │   │   • Microphone (future)
    │   │
    │   ├── SuggestedQuestions.swift    ← NEW
    │   │   • Quick action chips
    │   │   • Dynamic suggestions
    │   │   • Category-based
    │   │
    │   ├── SourceCitationCard.swift    ← NEW
    │   │   • Tafsir layer badge
    │   │   • Surah/verse reference
    │   │   • "View Tafsir" action
    │   │
    │   └── ChatSettingsView.swift      ← NEW
    │       • Appearance options
    │       • AI behavior toggles
    │       • Usage stats
    │       • Clear history
```

---

## 🔄 Data Flow & Decision Logic

### Query Processing Pipeline

```
┌───────────────────────────────────────────────────────┐
│ 1. USER SUBMITS QUESTION                              │
│    "What is the significance of Surah Al-Fatiha?"     │
└───────────────────────────────────────────────────────┘
                          ↓
┌───────────────────────────────────────────────────────┐
│ 2. PREPROCESSING                                      │
│    • Tokenize: ["significance", "Surah", "Al-Fatiha"]│
│    • Detect intent: SURAH_MEANING                     │
│    • Extract entity: Surah 1                          │
└───────────────────────────────────────────────────────┘
                          ↓
┌───────────────────────────────────────────────────────┐
│ 3. RAG SERVICE SEARCH                                 │
│    • Load tafsir_1.json                               │
│    • Search all layers (1-5) + summary                │
│    • Compute relevance scores                         │
│    • Top 3 matches:                                   │
│      - Layer 1 (Foundation): 0.92                     │
│      - Summary: 0.88                                  │
│      - Layer 3 (Contemporary): 0.75                   │
└───────────────────────────────────────────────────────┘
                          ↓
                    Confidence ≥ 0.7?
                          ↓
                        YES
                          ↓
┌───────────────────────────────────────────────────────┐
│ 4a. RETURN RAG RESULT                                 │
│    • Combine top matches                              │
│    • Format response                                  │
│    • Add source citations                             │
│    • Display time: ~200ms                             │
└───────────────────────────────────────────────────────┘

                    Confidence < 0.7?
                          ↓
                        YES
                          ↓
┌───────────────────────────────────────────────────────┐
│ 4b. OPENROUTER LLM CALL                               │
│    • Build prompt:                                    │
│      - System: "You are an Islamic scholar..."        │
│      - Context: Top RAG results as reference          │
│      - User question                                  │
│    • Model: anthropic/claude-3.5-sonnet               │
│    • Response time: ~2-4s                             │
│    • Add "AI-generated" badge                         │
└───────────────────────────────────────────────────────┘
                          ↓
┌───────────────────────────────────────────────────────┐
│ 5. DISPLAY RESPONSE                                   │
│    • Add to message list                              │
│    • Show source cards                                │
│    • Enable "View Tafsir" action                      │
└───────────────────────────────────────────────────────┘
```

### Confidence Scoring Algorithm

```swift
func calculateConfidence(query: String, matches: [KnowledgeChunk]) -> Double {
    var score: Double = 0.0

    // 1. Exact surah/verse match: +0.5
    if matches.contains(where: { matchesSurahVerse(query, $0) }) {
        score += 0.5
    }

    // 2. Keyword overlap: 0-0.3
    let queryKeywords = extractKeywords(query)
    let matchKeywords = matches.flatMap { $0.keywords }
    let overlap = Set(queryKeywords).intersection(Set(matchKeywords))
    score += min(Double(overlap.count) / Double(queryKeywords.count), 0.3)

    // 3. Content length: +0.1 (has substantial content)
    if matches.first?.content.count ?? 0 > 200 {
        score += 0.1
    }

    // 4. Multiple layer agreement: +0.1
    if matches.count >= 2 {
        score += 0.1
    }

    return min(score, 1.0)
}
```

---

## 💾 RAG Implementation Strategy

### Phase 1: Simple Keyword Matching (MVP)

**Pros**: Fast, no external dependencies, works offline
**Cons**: Less accurate for complex queries

```swift
class RAGService {
    // Pre-indexed knowledge base (loaded at app start)
    private var knowledgeBase: [KnowledgeChunk] = []

    struct KnowledgeChunk: Identifiable {
        let id: UUID
        let surahNumber: Int
        let verseNumber: Int?  // nil for surah-level content
        let layer: TafsirLayer
        let content: String
        let keywords: [String]  // Pre-extracted
    }

    // Initialize: Parse all tafsir files
    func indexTafsirData() async {
        // For each surah 1-114:
        //   Load tafsir_X.json
        //   For each verse:
        //     For each layer (1-5):
        //       Extract keywords (using NLTagger)
        //       Create KnowledgeChunk
        //   Add summary as separate chunk
    }

    // Search
    func search(query: String) -> SearchResult {
        let queryTokens = tokenize(query)

        var scored: [(chunk: KnowledgeChunk, score: Double)] = []
        for chunk in knowledgeBase {
            let score = calculateRelevance(queryTokens, chunk)
            if score > 0.3 {  // Threshold
                scored.append((chunk, score))
            }
        }

        // Sort by score, return top 3
        let top3 = scored.sorted { $0.score > $1.score }.prefix(3)

        return SearchResult(
            matches: top3.map { $0.chunk },
            confidence: top3.first?.score ?? 0.0
        )
    }

    private func calculateRelevance(_ queryTokens: [String],
                                   _ chunk: KnowledgeChunk) -> Double {
        // TF-IDF or simple keyword matching
        let matches = Set(queryTokens).intersection(Set(chunk.keywords))
        return Double(matches.count) / Double(queryTokens.count)
    }
}
```

### Phase 2: Vector Embeddings (Advanced - Future)

**Pros**: Much better accuracy, semantic understanding
**Cons**: Requires embeddings API or CoreML model

```swift
class RAGService {
    private var vectorStore: [VectorChunk] = []

    struct VectorChunk {
        let chunk: KnowledgeChunk
        let embedding: [Float]  // 1536-dim for OpenAI
    }

    func search(query: String) async throws -> SearchResult {
        // 1. Get query embedding
        let queryEmbedding = try await getEmbedding(query)

        // 2. Cosine similarity search
        var scored: [(chunk: KnowledgeChunk, similarity: Float)] = []
        for vectorChunk in vectorStore {
            let similarity = cosineSimilarity(queryEmbedding,
                                             vectorChunk.embedding)
            scored.append((vectorChunk.chunk, similarity))
        }

        // 3. Return top matches
        let top3 = scored.sorted { $0.similarity > $1.similarity }.prefix(3)
        return SearchResult(
            matches: top3.map { $0.chunk },
            confidence: Double(top3.first?.similarity ?? 0.0)
        )
    }

    private func getEmbedding(_ text: String) async throws -> [Float] {
        // Option A: OpenAI embeddings API
        // Option B: Local CoreML model
    }
}
```

---

## 🔐 OpenRouter Integration

### Configuration

```swift
// Config.swift (extend existing)
struct OpenRouterConfig {
    static let apiKey = ProcessInfo.processInfo.environment["OPENROUTER_API_KEY"]
                        ?? "YOUR_API_KEY_HERE"
    static let baseURL = "https://openrouter.ai/api/v1"
    static let defaultModel = "anthropic/claude-3.5-sonnet"
    static let fallbackModel = "openai/gpt-4o-mini"  // Cheaper
    static let temperature: Double = 0.7
    static let maxTokens = 1000
    static let timeout: TimeInterval = 30
}
```

### Service Implementation

```swift
@MainActor
class OpenRouterService: ObservableObject {
    struct ChatRequest: Codable {
        let model: String
        let messages: [Message]
        let temperature: Double
        let max_tokens: Int

        struct Message: Codable {
            let role: String  // "system", "user", "assistant"
            let content: String
        }
    }

    struct ChatResponse: Codable {
        let choices: [Choice]

        struct Choice: Codable {
            let message: Message
            struct Message: Codable {
                let content: String
            }
        }
    }

    func sendQuery(
        userQuestion: String,
        ragContext: [KnowledgeChunk]
    ) async throws -> String {

        // Build prompt
        let systemPrompt = """
        You are an expert Islamic scholar with deep knowledge of Shia traditions \
        and the Ahlul Bayt teachings. Answer questions using the provided tafsir \
        context. Be respectful, accurate, and cite sources when possible.

        Context from our tafsir library:
        \(formatContext(ragContext))
        """

        let messages = [
            ChatRequest.Message(role: "system", content: systemPrompt),
            ChatRequest.Message(role: "user", content: userQuestion)
        ]

        let request = ChatRequest(
            model: OpenRouterConfig.defaultModel,
            messages: messages,
            temperature: OpenRouterConfig.temperature,
            max_tokens: OpenRouterConfig.maxTokens
        )

        // HTTP request
        var urlRequest = URLRequest(url: URL(string: "\(OpenRouterConfig.baseURL)/chat/completions")!)
        urlRequest.httpMethod = "POST"
        urlRequest.addValue("Bearer \(OpenRouterConfig.apiKey)",
                           forHTTPHeaderField: "Authorization")
        urlRequest.addValue("application/json",
                           forHTTPHeaderField: "Content-Type")
        urlRequest.httpBody = try JSONEncoder().encode(request)
        urlRequest.timeoutInterval = OpenRouterConfig.timeout

        let (data, response) = try await URLSession.shared.data(for: urlRequest)

        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw OpenRouterError.invalidResponse
        }

        let chatResponse = try JSONDecoder().decode(ChatResponse.self, from: data)
        guard let content = chatResponse.choices.first?.message.content else {
            throw OpenRouterError.noContent
        }

        return content
    }

    private func formatContext(_ chunks: [KnowledgeChunk]) -> String {
        chunks.enumerated().map { index, chunk in
            """
            [Source \(index + 1)]
            Surah: \(chunk.surahNumber)
            Layer: \(chunk.layer.title)
            Content: \(chunk.content.prefix(500))...
            """
        }.joined(separator: "\n\n")
    }

    enum OpenRouterError: Error {
        case invalidResponse
        case noContent
        case rateLimitExceeded
    }
}
```

---

## 🎯 Premium Feature Gating

### Pricing Structure Overview

**THREE USER TIERS:**

1. **Free Users**: Limited chat access to try the feature
2. **One-time Purchase ($2.99)**: Lifetime tafsir access only (NO chat)
3. **Monthly Subscription ($4.99/mo)**: Unlimited AI Chat + Tafsir

### Feature Comparison Table

| Feature | Free Users | One-time Purchase | Monthly Subscription |
|---------|-----------|-------------------|---------------------|
| **Tafsir Access** | Surah 1 only | All 114 surahs ✅ | All 114 surahs ✅ |
| **AI Chat Access** | ✅ Yes | ❌ No | ✅ Yes |
| **Chat Messages** | 2 messages (then blocked) | N/A | Unlimited |
| **Answer Source** | RAG only | N/A | RAG + LLM fallback |
| **Response Quality** | Basic (RAG) | N/A | Advanced (multi-layer AI) |
| **Conversation History** | Last 10 messages | N/A | Unlimited history |
| **Download Chat** | ❌ | N/A | ✅ |
| **Advanced AI (LLM)** | ❌ | ❌ | ✅ |

### User Journey & Conversion Paths

**Free User Journey:**
1. Downloads app → Access to Surah 1 tafsir
2. Opens AI Chat → Can send 2 messages (RAG-powered)
3. Attempts 3rd message → Paywall appears with TWO options:
   - **Option A**: Subscribe ($4.99/mo) for unlimited chat + all tafsir
   - **Option B**: One-time purchase ($2.99) for all tafsir (no chat)

**One-time Purchase User Journey:**
1. Pays $2.99 → Unlocks all 114 surahs with full tafsir
2. Clicks AI Chat button → "Chat requires subscription" prompt
3. Can upgrade to subscription to add unlimited chat access

**Subscription User Journey:**
1. Pays $4.99/mo → Full access to everything
2. Unlimited chat messages with RAG + LLM
3. All 114 surahs with full tafsir commentary

### Implementation

```swift
@MainActor
class ChatManager: ObservableObject {
    @Published var messages: [ChatMessage] = []
    @Published var isLoading = false
    @Published var chatMessageCount: Int = 0  // Renamed from dailyQuestionCount
    @Published var errorMessage: String?

    private let premiumManager = PremiumManager.shared
    private let ragService = RAGService()
    private let openRouterService = OpenRouterService()

    private let FREE_CHAT_LIMIT = 2  // Changed from 5 to 2

    func sendMessage(_ text: String) async throws {
        // 1. Check access and rate limit
        guard canSendMessage() else {
            showChatPaywall()
            return
        }

        // 2. Add user message
        let userMessage = ChatMessage(
            id: UUID(),
            content: text,
            source: .user,
            timestamp: Date()
        )
        messages.append(userMessage)

        // 3. Start loading
        isLoading = true
        defer { isLoading = false }

        // 4. Try RAG first
        let ragResult = await ragService.search(query: text)

        if ragResult.confidence >= 0.7 {
            // RAG confidence is high - use local answer
            let botMessage = ChatMessage(
                id: UUID(),
                content: formatRAGResponse(ragResult),
                source: .bot,
                timestamp: Date(),
                metadata: .init(
                    sourceType: .rag,
                    surahRef: ragResult.matches.first.map {
                        SurahReference(surah: $0.surahNumber, verse: $0.verseNumber)
                    },
                    confidenceScore: ragResult.confidence
                )
            )
            messages.append(botMessage)

        } else if premiumManager.hasAIChatAccess {
            // Low confidence + Subscription → Use LLM
            let llmResponse = try await openRouterService.sendQuery(
                userQuestion: text,
                ragContext: ragResult.matches
            )

            let botMessage = ChatMessage(
                id: UUID(),
                content: llmResponse,
                source: .bot,
                timestamp: Date(),
                metadata: .init(
                    sourceType: .llm,
                    confidenceScore: nil
                )
            )
            messages.append(botMessage)

        } else {
            // Low confidence + Free user → Show RAG + suggest upgrade
            let botMessage = ChatMessage(
                id: UUID(),
                content: """
                I found some related information, but this question is complex. \
                Subscribe for AI-powered answers!

                Here's what I found:
                \(formatRAGResponse(ragResult))
                """,
                source: .bot,
                timestamp: Date(),
                metadata: .init(
                    sourceType: .rag,
                    confidenceScore: ragResult.confidence
                )
            )
            messages.append(botMessage)
        }

        // 5. Increment counter for free users
        if premiumManager.purchaseType == .none {
            chatMessageCount += 1
            saveChatCount()
        }
    }

    private func canSendMessage() -> Bool {
        // Subscription users: unlimited chat access
        if premiumManager.hasAIChatAccess {
            return true
        }

        // One-time purchase users: NO chat access
        if premiumManager.purchaseType == .oneTimePurchase {
            return false
        }

        // Free users: up to 2 messages
        return chatMessageCount < FREE_CHAT_LIMIT
    }

    private func showChatPaywall() {
        // Show appropriate paywall based on user type
        if premiumManager.purchaseType == .oneTimePurchase {
            // Show "Upgrade to subscription" for one-time users
            errorMessage = "AI Chat requires a monthly subscription. You have lifetime tafsir access."
        } else {
            // Show dual-option paywall for free users
            errorMessage = "You've used your 2 free chat messages. Subscribe for unlimited chat or purchase tafsir access."
        }
    }
}
```

---

## 📝 Data Models

### Complete Type Definitions

```swift
// MARK: - ChatModels.swift

import Foundation

// MARK: Message

struct ChatMessage: Identifiable, Codable {
    let id: UUID
    let content: String
    let source: MessageSource
    let timestamp: Date
    var metadata: MessageMetadata?

    enum MessageSource: String, Codable {
        case user
        case bot
        case system  // For errors, warnings
    }
}

// MARK: Metadata

struct MessageMetadata: Codable {
    let sourceType: SourceType?
    let surahRef: SurahReference?
    let confidenceScore: Double?

    enum SourceType: String, Codable {
        case rag      // Retrieved from local knowledge
        case llm      // Generated by AI
        case hybrid   // Combination
    }
}

struct SurahReference: Codable {
    let surah: Int
    let verse: Int?
}

// MARK: Search Result

struct SearchResult {
    let matches: [KnowledgeChunk]
    let confidence: Double
}

struct KnowledgeChunk: Identifiable {
    let id: UUID
    let surahNumber: Int
    let verseNumber: Int?
    let layer: TafsirLayer
    let content: String
    let keywords: [String]
}

// MARK: Question Categories

enum QuestionCategory {
    case surahMeaning       // "What is Surah X about?"
    case verseExplanation   // "Explain verse X:Y"
    case comparison         // "Shia vs Sunni on..."
    case ahlulBayt          // "What did Imam X say..."
    case general            // Open-ended
}
```

---

## 🚀 Implementation Phases

### Phase 1: Foundation (Week 1)
**Goal**: Basic UI and structure

- [ ] Create `ChatModels.swift`
- [ ] Create `ChatManager.swift` (empty state management)
- [ ] Create `ChatFloatingButton.swift`
  - Animated pulse effect
  - Theme-adaptive colors (warm/modern)
- [ ] Create `ChatView.swift`
  - Full-screen modal
  - Navigation bar
  - Empty state
- [ ] Add floating button to `ContentView.swift`
- [ ] Test navigation flow

**Deliverable**: Tappable chat button that opens full-screen view with "Coming Soon" message.

---

### Phase 2: RAG Service (Week 2)
**Goal**: Local knowledge search

- [ ] Create `RAGService.swift`
- [ ] Implement tafsir indexing at app launch
  - Parse all `tafsir_X.json` files
  - Extract keywords using `NLTagger`
  - Build in-memory knowledge base
- [ ] Implement keyword-based search
  - Tokenization
  - Relevance scoring (TF-IDF or simple matching)
- [ ] Test with sample queries
  - "What is Surah Al-Fatiha about?"
  - "Explain verse 2:255"
- [ ] Add source citation formatting

**Deliverable**: Working RAG that returns relevant tafsir passages with confidence scores.

---

### Phase 3: Chat UI (Week 2-3)
**Goal**: Interactive conversation interface

- [ ] Create `MessageBubble.swift`
  - User messages (right-aligned, gradient)
  - Bot messages (left-aligned, glass effect)
  - Timestamp display
- [ ] Create `ChatMessageList.swift`
  - ScrollView with auto-scroll to bottom
  - Loading indicator
- [ ] Create `ChatInputBar.swift`
  - Text field with placeholder
  - Send button (disabled when empty)
  - Character limit (500)
- [ ] Create `SuggestedQuestions.swift`
  - 4-6 quick action chips
  - Category-based suggestions
- [ ] Create `SourceCitationCard.swift`
  - Layer badge (Foundation 🏛️, etc.)
  - "View Tafsir" navigation action
- [ ] Wire up `ChatManager` to UI
  - Send message flow
  - Display RAG responses

**Deliverable**: Fully functional chat UI with RAG-powered responses.

---

### Phase 4: OpenRouter Integration (Week 3)
**Goal**: LLM fallback for complex queries

- [ ] Create `OpenRouterService.swift`
- [ ] Set up API key management (environment variable)
- [ ] Implement chat completion endpoint
  - Request/response models
  - Error handling
  - Timeout & retry logic
- [ ] Prompt engineering
  - System prompt with Shia context
  - RAG context injection
  - Response formatting
- [ ] Integrate with `ChatManager` decision logic
  - If confidence < 0.7 → call LLM
- [ ] Add "AI-generated" badge to LLM responses
- [ ] Test with complex queries
  - "Compare Shia and Sunni views on imamate"
  - "What would Imam Ali say about modern justice?"

**Deliverable**: Hybrid RAG + LLM system with intelligent fallback.

---

### Phase 5: Premium & Polish (Week 4)
**Goal**: Feature gating and refinement

- [ ] Implement rate limiting
  - Daily question counter (UserDefaults)
  - Reset at midnight
  - Paywall trigger when limit reached
- [ ] Add `ChatSettingsView.swift`
  - Appearance options
  - Clear history
  - Usage stats
- [ ] Conversation persistence
  - Save to UserDefaults or CoreData
  - Load on app launch
- [ ] Analytics tracking
  - Question count
  - RAG hit rate
  - LLM usage (cost tracking)
- [ ] UI polish
  - Animations (message fade-in)
  - Haptic feedback
  - Error states
  - Empty states
- [ ] Testing
  - Edge cases (empty responses, API errors)
  - Performance (large conversation history)
  - Accessibility (VoiceOver)

**Deliverable**: Production-ready chat feature with premium gating.

---

## 🎨 UI Styling Guide

### Colors & Themes

**Modern Dark Theme:**
```swift
// Bot messages
background: glassEffect (translucent)
border: strokeColor (purple-ish)
text: primaryText (white)

// User messages
background: purpleGradient
text: white

// Floating button
background: purpleGradient
shadow: purple with 0.4 opacity
```

**Warm Inviting Theme:**
```swift
// Bot messages
background: white
shadow: black with 0.04 opacity
text: Color(red: 0.176, green: 0.145, blue: 0.125)

// User messages
background: Color(red: 0.91, green: 0.604, blue: 0.435) // warm orange
text: white

// Floating button
background: Color(red: 0.91, green: 0.604, blue: 0.435)
shadow: matching color with 0.3 opacity
```

### Animations

```swift
// Floating button pulse
.scaleEffect(isPulsing ? 1.1 : 1.0)
.animation(
    Animation
        .easeInOut(duration: 1.5)
        .repeatForever(autoreverses: true),
    value: isPulsing
)

// Message fade-in
.opacity(isVisible ? 1.0 : 0.0)
.offset(y: isVisible ? 0 : 20)
.animation(.easeOut(duration: 0.3), value: isVisible)

// Typing indicator (three dots)
HStack(spacing: 4) {
    ForEach(0..<3) { index in
        Circle()
            .fill(Color.gray)
            .frame(width: 8, height: 8)
            .opacity(animatingDots[index] ? 1.0 : 0.3)
            .animation(
                Animation
                    .easeInOut(duration: 0.6)
                    .repeatForever()
                    .delay(Double(index) * 0.2),
                value: animatingDots[index]
            )
    }
}
```

---

## 📊 Analytics & Monitoring

### Key Metrics to Track

```swift
struct ChatAnalytics {
    // Usage
    var totalQuestions: Int
    var dailyQuestions: Int
    var averageQuestionsPerSession: Double

    // Performance
    var ragHitRate: Double           // % answered by RAG
    var llmHitRate: Double            // % answered by LLM
    var averageResponseTime: TimeInterval
    var averageConfidenceScore: Double

    // Engagement
    var conversationLengthAverage: Int  // Messages per conversation
    var sourceCitationClickRate: Double // % who click "View Tafsir"

    // Premium Conversion
    var paywallTriggers: Int
    var upgradesToPremium: Int
    var conversionRate: Double
}
```

---

## 🔒 Security & Privacy

### Best Practices

1. **API Key Security**
   - Store OpenRouter key in environment variable
   - Never commit to Git
   - Use `.gitignore` for config files

2. **User Data**
   - Chat history stored locally (UserDefaults or CoreData)
   - Optional cloud sync via Supabase (premium only)
   - Clear history option

3. **Rate Limiting**
   - Client-side enforcement (free tier)
   - Backend tracking (future)

4. **Content Moderation**
   - Filter inappropriate queries
   - Block offensive responses

---

## 💰 Cost Estimation & Revenue Model

### OpenRouter Pricing (Approximate)

**Model**: `anthropic/claude-3.5-sonnet`
- Input: $3 per 1M tokens
- Output: $15 per 1M tokens

**Typical query:**
- System prompt: ~200 tokens
- RAG context: ~500 tokens
- User question: ~50 tokens
- Response: ~300 tokens
- **Total**: ~1050 tokens per conversation turn

**Cost per LLM query**: ~$0.0053

### Monthly Cost Projections

**Scenario: 100 subscribers**
- Average LLM queries per subscriber: 20/month
- Total LLM queries: 100 × 20 = 2,000 queries
- **Monthly LLM cost**: 2,000 × $0.0053 = **$10.60**

**Scenario: 500 subscribers**
- Total LLM queries: 500 × 20 = 10,000 queries
- **Monthly LLM cost**: 10,000 × $0.0053 = **$53.00**

**Scenario: 1,000 subscribers**
- Total LLM queries: 1,000 × 20 = 20,000 queries
- **Monthly LLM cost**: 20,000 × $0.0053 = **$106.00**

### Revenue Projections

**Monthly Subscription: $4.99/month**

| Subscribers | Monthly Revenue (MRR) | LLM Costs | One-time Purchases | Net Margin |
|------------|----------------------|-----------|-------------------|------------|
| 100 | $499 | $10.60 | +$149.50 (50 @ $2.99) | **$637.90** |
| 500 | $2,495 | $53.00 | +$299 (100 @ $2.99) | **$2,741.00** |
| 1,000 | $4,990 | $106.00 | +$448.50 (150 @ $2.99) | **$5,332.50** |

**Conversion Funnel Assumptions:**
- Free-to-Subscription: 10% conversion rate
- Free-to-One-time: 5% conversion rate
- One-time-to-Subscription: 15% upgrade rate
- Free users: ~80% use 2 messages (try before buy)

### Optimization Strategies

1. **Maximize RAG hit rate** (target: 80%)
   - Reduce LLM calls by improving local search
   - Cost savings: 80% reduction in LLM usage

2. **Use cheaper model for simple queries**
   - Fallback to `openai/gpt-4o-mini` ($0.001 per query)
   - Potential 80% cost reduction on 50% of queries

3. **Cache common responses**
   - Store frequently asked questions
   - Estimated 20-30% query reduction

4. **Progressive upgrade prompts**
   - Free users exposed to chat value
   - One-time users shown subscription benefits
   - Target: 15% one-time → subscription upgrades

---

## ✅ Testing Checklist

### Functional Testing

- [ ] Chat button appears on main screen
- [ ] Button opens full-screen chat view
- [ ] Suggested questions are tappable
- [ ] User can type and send messages
- [ ] RAG returns relevant responses for common queries
- [ ] LLM fallback works for complex queries (premium)
- [ ] Source citations are clickable and navigate to tafsir
- [ ] Settings screen accessible and functional
- [ ] Clear history works correctly
- [ ] Rate limiting enforced for free users
- [ ] Paywall triggers at 5 questions/day

### Edge Cases

- [ ] Empty message handling
- [ ] Very long message (>500 chars)
- [ ] Network errors (offline mode)
- [ ] API timeout
- [ ] Invalid API key
- [ ] Rapid-fire messages
- [ ] Background/foreground transitions
- [ ] Memory pressure (large conversation history)

### Accessibility

- [ ] VoiceOver support for all UI elements
- [ ] Dynamic type scaling
- [ ] Color contrast compliance
- [ ] Keyboard navigation (iPad)

---

## 🎯 Success Criteria

### MVP (Phase 1-3)
✅ Chat button visible on main screen
✅ Full-screen chat interface functional
✅ RAG-powered responses working
✅ Basic conversation flow complete
✅ 70%+ RAG hit rate for common queries
✅ Free users can send 2 messages
✅ 3rd message shows dual-option paywall

### Production (Phase 4-5)
✅ OpenRouter LLM integration live
✅ Dual pricing structure implemented
  - Monthly subscription product configured
  - One-time purchase product configured
✅ Feature gating for three user tiers
  - Free: 2 chat messages
  - One-time: Tafsir only (no chat)
  - Subscription: Unlimited chat + tafsir
✅ Rate limiting enforced correctly
✅ Analytics tracking active
✅ Average response time < 2 seconds
✅ User satisfaction > 4/5 stars

### Business Metrics (First 3 Months)
✅ **Conversion Targets:**
  - Free-to-Subscription: 10%+ conversion
  - Free-to-One-time: 5%+ conversion
  - One-time-to-Subscription: 15%+ upgrade rate

✅ **Revenue Targets:**
  - Month 1: $500+ MRR (101 subscribers)
  - Month 3: $1,500+ MRR (301 subscribers)
  - LLM costs < 5% of subscription revenue

✅ **Engagement Metrics:**
  - 80%+ of free users try chat (send at least 1 message)
  - 60%+ of free users reach 2-message limit
  - Average session: 3+ messages per conversation
  - RAG hit rate: 75%+ (minimize LLM costs)

---

## 📚 Resources

### Documentation
- [OpenRouter API Docs](https://openrouter.ai/docs)
- [Anthropic Claude API](https://docs.anthropic.com/claude/reference)
- [Apple NLTagger](https://developer.apple.com/documentation/naturallanguage/nltagger)

### Inspiration
- ChatGPT iOS app (conversation UI)
- Perplexity AI (source citations)
- Character.AI (suggested questions)

---

## 🤝 Future Enhancements (Post-MVP)

1. **Voice Input** - Microphone button for speech-to-text
2. **Voice Output** - Text-to-speech for responses
3. **Conversation History Sync** - Cloud backup via Supabase
4. **Share Conversations** - Export as text/PDF
5. **Multilingual Support** - Arabic, Urdu responses
6. **Advanced RAG** - Vector embeddings for better accuracy
7. **Streaming Responses** - Real-time LLM output
8. **Context Awareness** - Remember previous messages in conversation
9. **Suggested Follow-ups** - "Ask me about..." after each response
10. **Personalization** - Learn from user preferences over time

---

## 📋 Dual Pricing Structure Summary

### Key Changes from Original Plan

1. **Three User Tiers**:
   - **Free**: 2 chat messages (RAG-only), Surah 1 tafsir
   - **One-time Purchase ($2.99)**: All 114 surahs tafsir, NO chat access
   - **Monthly Subscription ($4.99/mo)**: Unlimited chat + all tafsir

2. **Chat Access Rules**:
   - Free users: 2 RAG-powered messages, then blocked
   - One-time users: Chat button blocked entirely (subscription required)
   - Subscription users: Unlimited chat with RAG + LLM

3. **Conversion Funnel**:
   ```
   Free User (2 messages)
   ├─→ Subscribe $4.99/mo (unlimited chat + tafsir) ⭐ PRIMARY
   └─→ Buy once $2.99 (tafsir only, no chat)

   One-time User
   └─→ Upgrade to subscription $4.99/mo (add chat) ⭐ UPSELL
   ```

4. **Revenue Model**:
   - MRR from subscriptions (recurring)
   - One-time revenue from tafsir purchases
   - 15% upgrade rate from one-time → subscription expected

5. **Implementation Priority**:
   - Dual PaywallView with side-by-side options
   - ChatPaywallView for free users (after 2 messages)
   - ChatPaywallView for one-time users (subscription upsell)
   - PremiumManager updates: `purchaseType`, `hasAIChatAccess`
   - PurchaseManager: subscription product handling
   - Database schema: track purchase type and subscription status

---

**Last Updated**: November 9, 2025
**Status**: Ready for Implementation with Dual Pricing Structure
**Estimated Timeline**: 4 weeks (MVP) + 1 week (subscription integration)
**Priority**: High - Premium conversion feature with recurring revenue

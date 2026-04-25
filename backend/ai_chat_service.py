from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from langchain_openai import ChatOpenAI
from langchain_core.messages import SystemMessage, HumanMessage, AIMessage
import os
import uvicorn
from dotenv import load_dotenv
from supabase import create_client

load_dotenv()

supabase_client = create_client(os.getenv("SUPABASE_URL", ""), os.getenv("SUPABASE_ANON_KEY", ""))

app = FastAPI(title="Campus Pocket AI Chat Service")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

class ChatRequest(BaseModel):
    user_id: str
    role: str
    query: str
    context: dict
    history: list = []

def build_llm():
    return ChatOpenAI(
        api_key=os.getenv("OPENAI_API_KEY"),
        base_url="https://openrouter.ai/api/v1",
        model="gpt-4o-mini",
        temperature=0.4,
        max_tokens=1024
    )

async def build_rag_context_string(context: dict, role: str) -> str:
    """
    Convert the context dict into a rich, structured RAG knowledge base string
    that the LLM can use to answer queries with real data.
    Now queries Supabase for 100% accurate real time data.
    """
    lines = ["=== REAL-TIME STUDENT DATA (Use this for all answers) ==="]

    student_id = context.get("studentId") or context.get("selectedChildId") or context.get("student_id")
    
    if student_id:
        try:
            # Fetch real-time attendance
            att_resp = supabase_client.table("student_attendance_summary").select("*").eq("student_id", student_id).execute()
            # Fetch real-time grades
            grd_resp = supabase_client.table("student_grade_summary").select("*").eq("student_id", student_id).execute()
            # Fetch pending assignments
            ass_resp = supabase_client.table("assignment_submission").select("*").eq("user_id", student_id).is_("score", "null").execute()
            
            if att_resp.data:
                att_data = att_resp.data[0]
                pct = att_data.get("attendance_percentage", 0)
                present = att_data.get("present_count", 0)
                absent = att_data.get("absent_count", 0)
                lines.append(f"Real-time Attendance: {pct}% ({present} Present, {absent} Absent)")
                if pct < 75:
                    lines.append("⚠️ CRITICAL: Attendance is below 75%. Parent intervention required immediately.")
            
            if grd_resp.data:
                grd_data = grd_resp.data[0]
                pct = grd_data.get("average_percentage", 0)
                lines.append(f"Real-time Average Marks: {pct}%")
                if pct < 50:
                    lines.append("⚠️ CRITICAL: Academic performance is poor. Needs immediate focus.")
                    
            if ass_resp.data:
                lines.append(f"Pending Assignments: {len(ass_resp.data)}")
                if len(ass_resp.data) >= 3:
                    lines.append("⚠️ CRITICAL: High number of pending assignments. Student might be facing burnout or time management issues.")
            else:
                lines.append("Pending Assignments: 0")
                
            # Fetch specific recent assignment marks
            recent_ass_resp = supabase_client.table("assignment_submission").select("*, assignment(title)").eq("user_id", student_id).not_.is_("score", "null").order("submitted_at", desc=True).limit(5).execute()
            if recent_ass_resp.data:
                lines.append("\nRecent Assignment Grades:")
                for a in recent_ass_resp.data:
                    title = a.get("assignment", {}).get("title", "Assignment")
                    pct = a.get("percentage")
                    lines.append(f"  - {title}: {pct}%")

        except Exception as e:
            lines.append(f"[RAG Database Fetch Error: {e}]")
            
    # ── Parent context ──────────────────────────────────────────────────
    if role == "parent":
        parent_name = context.get("parentName") or context.get("parent_name", "Parent")
        lines.append(f"Parent Name: {parent_name}")

        children = context.get("children", [])
        if children:
            lines.append(f"\nLinked Children ({len(children)} total):")
            for i, c in enumerate(children, 1):
                name = c.get("name", f"Child {i}")
                att = c.get("attendance")
                grade = c.get("grade") or c.get("avg_grade")
                fee = c.get("feeStatus") or c.get("fee_status", "unknown")
                lines.append(f"  [{i}] {name} (Attendance: {att}%, Grade: {grade}%, Fee: {fee})")

        selected_child = context.get("selectedChild")
        if selected_child:
            lines.append(f"\nCurrently Viewing Child: {selected_child} (ID: {student_id})")

    # ── Student context ─────────────────────────────────────────────────
    elif role == "student":
        student_name = context.get("studentName") or context.get("student_name", "Student")
        lines.append(f"Student Name: {student_name}")

    # ── Shared extra context fields ─────────────────────────────────────
    extra_instruction = context.get("system_instruction")
    if extra_instruction:
        lines.append(f"\nAdditional Instruction: {extra_instruction}")

    lines.append("\n=== END OF DATA ===")
    return "\n".join(lines)


@app.post("/chat")
async def chat_endpoint(req: ChatRequest):
    try:
        llm = build_llm()

        # ── Build rich RAG system prompt ────────────────────────────────
        if req.role == "parent":
            system_prompt = """You are Campus Pocket Parent AI — an intelligent, empathetic school assistant for parents.

CORE RULES:
1. You have access to REAL real-time data about the parent's children (provided below). USE IT in every answer.
2. Always be specific — reference actual percentages, names, and statuses from the data.
3. Give DETAILED, DESCRIPTIVE answers with clear structure (use bullet points, sections, emojis).
4. Proactively highlight risks (low attendance, overdue fees, poor grades) even if not asked directly.
5. If asked to send a message to a teacher, reply EXACTLY: ACTION:SEND_MESSAGE|<teacher_name>|<subject>|<message_body>
6. Refuse non-school topics politely but firmly.
7. Respond in the SAME LANGUAGE the parent used to ask (English / Hindi / Telugu).

CAPABILITIES:
- Summarize each child's academic performance with insights
- Identify at-risk children (attendance < 75%, grades < 50%)
- Explain fee status and urgency
- Draft messages to teachers
- Give personalized weekly action plans
- Compare performance across subjects
- Suggest study strategies based on weak areas"""

        else:  # student
            system_prompt = """You are Campus Pocket Student AI — an academic coach and motivator.

CORE RULES:
1. You have access to REAL real-time data about the student (provided below). USE IT.
2. Be specific — reference actual marks, subjects, and percentages from the data.
3. Give DETAILED, DESCRIPTIVE answers with study tips, action plans, and encouragement.
4. Proactively flag risks (attendance warnings, weak subjects, burnout signs).
5. Respond in the SAME LANGUAGE the student used (English / Hindi / Telugu).
6. Refuse non-academic topics politely.

CAPABILITIES:
- Analyze subject-wise performance trends
- Create personalized study plans
- Warn about attendance thresholds
- Identify burnout signals
- Suggest exam preparation strategies"""

        # ── Build RAG knowledge base from live data ─────────────────────
        rag_context = await build_rag_context_string(req.context, req.role)

        messages = [
            SystemMessage(content=system_prompt),
            SystemMessage(content=rag_context),
        ]

        # ── Inject conversation history ─────────────────────────────────
        for msg in req.history[-10:]:  # last 10 messages only
            content = msg.get("content", "")
            if msg.get("role") == "user" or msg.get("isUser") == True:
                messages.append(HumanMessage(content=content))
            else:
                messages.append(AIMessage(content=content))

        messages.append(HumanMessage(content=req.query))

        response = llm.invoke(messages)

        # Log to Supabase (best-effort)
        try:
            supabase_client.table("ai_chat_logs").insert({
                "user_id": req.user_id,
                "role": req.role,
                "query": req.query,
                "response": response.content,
            }).execute()
        except Exception:
            pass

        return {"response": response.content, "role": req.role}

    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@app.get("/health")
async def health():
    return {"status": "ok"}


if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=8000)

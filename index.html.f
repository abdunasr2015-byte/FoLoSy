<!DOCTYPE html>
<html lang="ar" dir="rtl">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>FoLoSy - حسابات رحيم الاحترافية</title>
  <script src="https://cdn.jsdelivr.net/npm/chart.js"></script>
  <style>
:root {
    --bg: #121212;
    --card: #1e1e1e;
    --success: #28a745;
    --danger: #dc3545;
    --accent: #007bff;
  }
    body {
      font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
      background-color: var(--bg);
      color: white;
      padding: 10px;
      margin: 0;
      text-align: center;
    }
    .balance-card {
      background: linear-gradient(45deg, #1a2a6c, #b21f1f);
      padding: 20px;
      border-radius: 15px;
      margin-bottom: 15px;
      box-shadow: 0 4px 15px rgba(0,0,0,0.5);
    }
    .balance-value {
      font-size: 32px;
      font-weight: bold;
      margin-top: 5px;
    }
    .input-group {
      background: var(--card);
      padding: 15px;
      border-radius: 12px;
      margin-bottom: 15px;
      border: 1px solid #333;
    }
    input, select {
      width: 95%;
      padding: 12px;
      margin: 8px 0;
      border-radius: 8px;
      background: #222;
      color: white;
      border: 1px solid #444;
      font-size: 16px;
    }
    .btn-row {
      display: flex;
      gap: 10px;
      margin-top: 10px;
    }
    .btn {
      border: none;
      padding: 15px;
      border-radius: 8px;
      color: white;
      font-weight: bold;
      cursor: pointer;
      flex: 1;
      font-size: 16px;
      transition: 0.3s;
    }
    .mic-btn {
      background: #6f42c1;
      border-radius: 50%;
      width: 60px;
      height: 60px;
      margin: 10px auto;
      display: flex;
      align-items: center;
      justify-content: center;
      font-size: 24px;
      box-shadow: 0 0 15px #6f42c1;
    }
    .mic-active {
      animation: pulse 1.5s infinite;
      background: var(--danger);
    }
    @keyframes pulse {
      0% {
        transform: scale(1);
      }

      50% {
        transform: scale(1.1);
      }

      100% {
        transform: scale(1);
      }
    }
    .filter-group {
      background: #252525;
      padding: 10px;
      border-radius: 10px;
      margin-bottom: 15px;
      display: flex;
      flex-wrap: wrap;
      gap: 5px;
      justify-content: center;
    }
    .filter-group input {
      width: 40%;
      font-size: 12px;
      padding: 5px;
    }
    table {
      width: 100%;
      border-collapse: collapse;
      margin-top: 10px;
      background: var(--card);
      border-radius: 10px;
      overflow: hidden;
    }
    th, td {
      border: 1px solid #333;
      padding: 10px;
      font-size: 13px;
      text-align: center;
    }
    .action-btn {
      padding: 5px 8px;
      border-radius: 5px;
      border: none;
      color: white;
      cursor: pointer;
      margin: 2px;
      font-size: 11px;
    }
    @media print {
      .input-group, .mic-btn, .filter-group, .action-btn, .btn-row {
        display: none;
      }

      body {
        background: white;
        color: black;
      }

      table {
        color: black;
        border: 1px solid black;
      }
    }
  </style>
</head>
<body>

  <div class="balance-card">
    <div>
      إجمالي الرصيد الحالي 💰
    </div>
    <div id="liveBalance" class="balance-value">
      0.00
    </div>
  </div>

  <div class="mic-btn" id="micBtn" onclick="startVoice()">
    🎙️
  </div>
  <div id="micStatus" style="font-size: 12px; color: #aaa; margin-bottom: 10px;">
    اضغط للتحدث (ذكاء اصطناعي)
  </div>

  <div class="input-group">
    <input type="text" id="description" placeholder="البيان (أو اتكلم بالمايك)">
    <input type="number" id="amount" placeholder="المبلغ">
    <select id="type">
      <option value="income">إيراد (+)</option>
      <option value="expense">مصروف (-)</option>
    </select>
    <div class="btn-row">
      <button id="addBtn" class="btn" style="background:var(--success);" onclick="addEntry()">إضافة</button>
      <button id="printBtn" class="btn" style="background:var(--accent);" onclick="window.print()">طباعة تقرير</button>
    </div>
  </div>

  <div class="filter-group">
    <label style="width:100%; font-size:12px;">تصفية بالتاريخ (تقارير):</label>
    <input type="date" id="fromDate" onchange="updateUI()">
    <input type="date" id="toDate" onchange="updateUI()">
  </div>

  <div style="overflow-x:auto;">
    <table id="mainTable">
      <thead>
        <tr>
          <th>التاريخ</th>
          <th>البيان</th>
          <th>المبلغ</th>
          <th>إجراء</th>
        </tr>
      </thead>
      <tbody id="tableBody"></tbody>
    </table>
  </div>

  <script>
    let transactions = JSON.parse(localStorage.getItem('rahim_pro_v5') || "[]");
    let editIndex = -1;

    // دالة المايك الذكي
    function startVoice() {
      const recognition = new (window.SpeechRecognition || window.webkitSpeechRecognition)();
      recognition.lang = 'ar-SA';
      const btn = document.getElementById('micBtn');
      const status = document.getElementById('micStatus');

      recognition.onstart = () => {
        btn.classList.add('mic-active');
        status.innerText = "جاري الاستماع... (قول مثلاً: صرفت 100 خضار)";
      };

      recognition.onresult = (event) => {
        const text = event.results[0][0].transcript;
        document.getElementById('description').value = text;
        analyzeText(text);
        btn.classList.remove('mic-active');
        status.innerText = "تم التحليل!";
      };

      recognition.onerror = () => {
        btn.classList.remove('mic-active');
        status.innerText = "خطأ في المايك، حاول تاني";
      };

      recognition.start();
    }

    function analyzeText(text) {
      // استخراج المبلغ
      const numbers = text.match(/\d+/);
      if (numbers) document.getElementById('amount').value = numbers[0];

      // استخراج النوع
      if (text.includes("صرفت") || text.includes("دفعت") || text.includes("مصروف")) {
        document.getElementById('type').value = "expense";
      } else if (

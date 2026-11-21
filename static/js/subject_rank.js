// 과목별 성적조회 — 제목 클릭 정렬 + 이름 검색 (아이디어·첫 코드: 김상민)
// 브라우저 안에서만 정렬하므로 서버에 다시 요청하지 않음
var curCol = null;   // 지금 정렬 중인 칸 번호
var isDesc = true;   // true = 높은 점수부터

function sortTable(columnIndex) {
    var tbody = document.getElementById("score_body");
    var rows = Array.from(tbody.rows);
    if (rows.length < 2) return;

    // 같은 칸을 다시 누르면 순서를 뒤집고, 다른 칸이면 높은 순부터
    isDesc = (curCol === columnIndex) ? !isDesc : true;
    curCol = columnIndex;

    rows.sort(function (a, b) {
        var aNum = Number(a.cells[columnIndex].textContent.trim());
        var bNum = Number(b.cells[columnIndex].textContent.trim());
        return isDesc ? bNum - aNum : aNum - bNum;
    });
    rows.forEach(function (row) { tbody.appendChild(row); });   // 정렬된 순서로 다시 붙이기

    // 지금 정렬 중인 칸 표시
    document.querySelectorAll("th.sortable").forEach(function (th) {
        var active = Number(th.dataset.col) === columnIndex;
        th.classList.toggle("active", active);
        th.querySelector(".sort-icon").textContent = active ? (isDesc ? "▼" : "▲") : "⮃";
    });
}

// 숫자 칸(국어·영어·수학·총점·평균)만 정렬
document.querySelectorAll("th.sortable").forEach(function (th) {
    th.addEventListener("click", function () { sortTable(Number(th.dataset.col)); });
});

// 이름 검색: 입력할 때마다 맞는 줄만 보여줌
document.getElementById("search").addEventListener("input", function (e) {
    var term = e.target.value.trim().toLowerCase();
    document.querySelectorAll("#score_body tr").forEach(function (row) {
        var nameCell = row.querySelector(".student-name");
        if (!nameCell) return;   // "등록된 학생이 없습니다" 줄
        row.style.display = nameCell.textContent.toLowerCase().includes(term) ? "" : "none";
    });
});

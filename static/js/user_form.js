// 계정 발급 폼 — 역할에 따라 칸 보이기/숨기기, 학교를 고르면 학생 목록 불러오기
function toggleFields() {
    var role = $("#role").val();
    $(".school-field").toggle(role !== "admin");     // 관리자는 학교 없음
    $(".student-field").toggle(role === "student");  // 학생만 학생 번호 연결
}

function loadStudents() {
    var schoolcode = $("#schoolcode").val();
    var $bunho = $("#bunho");
    var selected = String($bunho.data("selected") || "");
    $bunho.empty();
    if (!schoolcode) {
        $bunho.append($("<option value=''>").text("-- 학교를 먼저 선택 --"));
        return;
    }
    // 성적표 검색과 같은 /_search 를 이름 없이 호출 → 그 학교 학생 전체
    $.getJSON("/_search", { schoolcode: schoolcode, name: "" }, function (data) {
        $bunho.append($("<option value=''>").text("-- 학생 선택 (" + data.result.length + "명) --"));
        $.each(data.result, function (i, s) {
            $bunho.append($("<option>").val(s.bunho).text(s.bunho + "번 " + s.name)
                .prop("selected", String(s.bunho) === selected));
        });
    });
}

$("#role").on("change", function () {
    toggleFields();
    if ($(this).val() === "student") loadStudents();
});
$("#schoolcode").on("change", function () {
    $("#bunho").data("selected", "");
    if ($("#role").val() === "student") loadStudents();
});
// 학생을 고르면 이름 칸을 자동으로 채움
$("#bunho").on("change", function () {
    var text = $(this).find("option:selected").text();
    var match = text.match(/^\d+번 (.+)$/);
    if (match && $("#name").val() === "") $("#name").val(match[1]);
});

$("#userForm").on("submit", function () {
    var role = $("#role").val(), error = "";
    if (!/^[A-Za-z0-9_]{4,30}$/.test($("#login_id").val())) error = "아이디는 영문·숫자·_ 로 4~30자여야 합니다.";
    else if ($("#password").val().length < 8) error = "비밀번호는 8자 이상이어야 합니다.";
    else if ($.trim($("#name").val()) === "") error = "이름을 입력하세요.";
    else if (role !== "admin" && !$("#schoolcode").val()) error = "소속 학교를 선택하세요.";
    else if (role === "student" && !$("#bunho").val()) error = "연결할 학생을 선택하세요.";
    if (error) {
        $("#form_error").text(error);
        return false;
    }
    return true;
});

$(".delete-form").on("submit", function () {
    return confirm("이 계정을 삭제할까요?");
});

toggleFields();
if ($("#role").val() === "student") loadStudents();

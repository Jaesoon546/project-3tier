// 학생 등록·수정 폼 검사 (HTML 16_form_check 실습 방식)
// 서버(service/grade.py)에서도 한 번 더 검사하므로, 여기서는 사용자가 빨리 알 수 있게 하는 용도
$("#sungjukForm").on("submit", function () {
    var error = "";
    if ($.trim($("#name").val()) === "") {
        error = "이름을 입력하세요.";
    }
    $(".score").each(function () {
        var label = $("label[for='" + this.id + "']").text();
        var value = $(this).val();
        var score = Number(value);
        if (!error && (value === "" || !Number.isInteger(score) || score < 0 || score > 100)) {
            error = label + " 점수는 0~100 사이 숫자로 입력하세요.";
        }
    });
    if (error) {
        $("#form_error").text(error);
        return false;   // 전송 막기
    }
    return true;
});

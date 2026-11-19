// 이름 검색 — /_search 를 AJAX로 호출해서 성적표를 다시 그림
// (Flask ajax.html 실습의 $.getJSON 방식)
function drawRows(rows) {
    var $body = $("#sungjuk_body");
    var withButtons = $("th:contains('수정')").length > 0;   // 교사 화면이면 수정·삭제 버튼도 그림
    var csrf = $("input[name='csrf_token']").first().val();
    $body.empty();

    if (rows.length === 0) {
        $body.append($("<tr>").append($("<td colspan='11'>").text("검색 결과가 없습니다.")));
        return;
    }
    $.each(rows, function (i, s) {
        var $tr = $("<tr>");
        // .text()로 넣어야 이름에 HTML이 섞여 있어도 안전함
        $.each([s.ranks, s.bunho, s.name, s.kor, s.eng, s.mat, s.total, s.average, s.grade], function (j, v) {
            $tr.append($("<td>").text(v));
        });
        if (withButtons) {
            $tr.append($("<td>").append(makeForm("/sungjuk_update", s.bunho, csrf, "성적 수정", "btn-outline-primary")));
            $tr.append($("<td>").append(makeForm("/sungjuk_delete", s.bunho, csrf, "성적 삭제", "btn-outline-danger")
                .on("submit", function () { return confirm("정말 삭제할까요?"); })));
        }
        $body.append($tr);
    });
}

function makeForm(action, bunho, csrf, label, style) {
    return $("<form method='post'>").attr("action", action)
        .append($("<input type='hidden' name='csrf_token'>").val(csrf))
        .append($("<input type='hidden' name='bunho'>").val(bunho))
        .append($("<button type='submit'>").addClass("btn btn-sm " + style).text(label));
}

function search(name) {
    $.getJSON("/_search", { schoolcode: $("#schoolcode").val(), name: name }, function (data) {
        drawRows(data.result);
    });
}

$("#search_btn").on("click", function () { search($("#search_name").val()); });
$("#search_name").on("keyup", function (e) { if (e.key === "Enter") search($(this).val()); });
$("#reset_btn").on("click", function () { $("#search_name").val(""); search(""); });

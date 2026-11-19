from dao.db import select_proc, select_proc_one, result_proc


def getSungjuk(schoolcode):
    """학교별 성적표 (등수 순)"""
    return select_proc("student_select", (schoolcode,))


def getStudent(bunho):
    return select_proc_one("student_select_one", (bunho,))


def searchStudent(schoolcode, name):
    return select_proc("student_search", (schoolcode, name))


def insertStudent(student, schoolcode):
    """student : service.grade.Student"""
    return result_proc("student_insert", (
        student.name, student.kor, student.mat, student.eng,
        student.total(), round(student.avg(), 2), student.grade(),
        schoolcode, 0))


def updateStudent(bunho, student):
    return result_proc("student_update", (
        bunho, student.name, student.kor, student.mat, student.eng,
        student.total(), round(student.avg(), 2), student.grade(), 0))


def deleteStudent(bunho):
    return result_proc("student_delete", (bunho, 0))


def getStats(schoolcode):
    """과목별 합계·평균·최고·최저"""
    return select_proc("student_stats", (schoolcode,))


def getHistory(schoolcode):
    """성적 수정·삭제 이력"""
    return select_proc("history_select", (schoolcode,))

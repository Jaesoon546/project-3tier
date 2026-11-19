from dao.db import select_proc, select_proc_one, result_proc


def getSchoolList():
    return select_proc("school_select")


def getSchool(schoolcode):
    return select_proc_one("school_select_one", (schoolcode,))


def insertSchool(schoolcode, schoolname, address):
    return result_proc("school_insert", (schoolcode, schoolname, address, 0))

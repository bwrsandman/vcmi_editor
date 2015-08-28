#include <check.h>
#include "../c_editor_utils.h"


START_TEST(test_NormalizeResourceName)
{
    char * path = "/pp\\bin/win32\\ppc386.txt";
    ck_assert_str_eq(NormalizeResourceName(path), "/PP/BIN/WIN32/PPC386");
    ck_assert_str_eq(path, "/pp\\bin/win32\\ppc386.txt");
}
END_TEST

Suite * editor_utils_suite()
{
    Suite * s;
    TCase * tc_core;

    s = suite_create("Editor Utils");

    /* Core test case */
    tc_core = tcase_create("Core");

    tcase_add_test(tc_core, test_NormalizeResourceName);
    suite_add_tcase(s, tc_core);

    return s;
}

int main(void)
{
    int fails;
    Suite * s;
    SRunner * sr;

    s = editor_utils_suite();
    sr = srunner_create(s);

    srunner_run_all(sr, CK_NORMAL);
    fails = srunner_ntests_failed(sr);
    srunner_free(sr);

    return fails;
}

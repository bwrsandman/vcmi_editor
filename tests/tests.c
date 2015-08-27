#include <check.h>
#include "../c_editor_utils.h"


START_TEST(test_NormalizeResourceName)
{
    char * path = "/pp\\bin/win32\\ppc386.txt";
    ck_assert_str_eq(NormalizeResourceName(path), "/PP/BIN/WIN32/PPC386");
    ck_assert_str_eq(path, "/pp\\bin/win32\\ppc386.txt");
}
END_TEST

START_TEST(test_LEtoNinPlace)
{
    unsigned int val = 0xFF;
    LEtoNinPlace(&val);
    if (ENDIAN_LITTLE)
        ck_assert_uint_eq(0xFF, val);
    else
        ck_assert_uint_eq(0xFF000000, val);

    val = 0xFF000000;
    LEtoNinPlace(&val);
    if (ENDIAN_LITTLE)
        ck_assert_uint_eq(0xFF000000, val);
    else
        ck_assert_uint_eq(0xFF, val);

    val = 0x12345678;
    LEtoNinPlace(&val);
    if (ENDIAN_LITTLE)
        ck_assert_uint_eq(0x12345678, val);
    else
        ck_assert_uint_eq(0x78563412, val);
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
    tcase_add_test(tc_core, test_LEtoNinPlace);
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

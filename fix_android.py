"""Raises compileSdk to 36 for the app and all Flutter plugins (run in CI after flutter create).

Flutter's root build file already evaluates :app before the plugins, so afterEvaluate is not
allowed there. plugins.withId runs when each Android library is applied, which is safe.
"""
import os
import re

MARK = '// aban-as: compileSdk 36 for plugins'
APP = 'android/app/build.gradle.kts'
ROOT = 'android/build.gradle.kts'

if os.path.exists(APP):
    s = open(APP, encoding='utf-8').read()
    s = re.sub(r'compileSdk\s*=\s*[^\n]+', 'compileSdk = 36', s)
    open(APP, 'w', encoding='utf-8').write(s)
    print('app compileSdk set to 36')

if os.path.exists(ROOT):
    s = open(ROOT, encoding='utf-8').read()
    # remove a block written by an earlier run of this script
    if MARK in s:
        s = s[:s.index(MARK)].rstrip() + '\n'
    s = s.replace('import com.android.build.gradle.BaseExtension\n', '')
    block = (
        f"\n{MARK}\n"
        "subprojects {\n"
        "    plugins.withId(\"com.android.library\") {\n"
        "        extensions.configure<com.android.build.gradle.BaseExtension> {\n"
        "            compileSdkVersion(36)\n"
        "        }\n"
        "    }\n"
        "}\n"
    )
    open(ROOT, 'w', encoding='utf-8').write(s + block)
    print('plugins compileSdk set to 36')

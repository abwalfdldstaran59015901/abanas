"""Raises compileSdk to 36 for the app and all Flutter plugins (run in CI after flutter create)."""
import os
import re

APP = 'android/app/build.gradle.kts'
ROOT = 'android/build.gradle.kts'

if os.path.exists(APP):
    s = open(APP, encoding='utf-8').read()
    s = re.sub(r'compileSdk\s*=\s*[^\n]+', 'compileSdk = 36', s)
    open(APP, 'w', encoding='utf-8').write(s)
    print('app compileSdk set to 36')

if os.path.exists(ROOT):
    s = open(ROOT, encoding='utf-8').read()
    if 'compileSdkVersion(36)' not in s:
        block = (
            "\nsubprojects {\n"
            "    afterEvaluate {\n"
            "        extensions.findByName(\"android\")?.let {\n"
            "            (it as BaseExtension).compileSdkVersion(36)\n"
            "        }\n"
            "    }\n"
            "}\n"
        )
        s = 'import com.android.build.gradle.BaseExtension\n' + s + block
        open(ROOT, 'w', encoding='utf-8').write(s)
        print('plugins compileSdk set to 36')

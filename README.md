# jar2app

Creates a .app file for macOS from JAR

### Pre-conditions:

[**macOS Device**](https://www.apple.com/mac/)\
[**java**](https://www.java.com/download/manual.jsp)\
**.jar file**

### Resources

- universalJavaApplicationStub: [https://github.com/tofi86/universalJavaApplicationStub](https://github.com/tofi86/universalJavaApplicationStub)

### How to create the .app file using the script?

- Run the script

```bash
#bash jar2app.sh -h
Usage: jar2app.sh [-h] [-a app_name] [-b bundle_name] [-j jar_path] [-i icns_path] [-o output_path] [-v java_version] [app_arguments...]
Creates a .app file for MacOS from a jar file
Where:
  app_name     - name of the .app without the extension
  bundle_name  - name of the .app bundler identifier
                 default: 'com.jar2app.app_name'
  jar_path     - absolute path for the .jar file
  icns_path    - absolute path for the .icns file
                 default: './jar2app/default.icns'
  output_path  - absolute directory for the generated .app
                 default: './jar2app'
  java_version - required java runtime version
                 eg: '1.8', '1.8*', '1.8+', '11*', '11.0+'
                 default: do no check for java runtime version
```

const fs = require('fs');
let c = fs.readFileSync('android/app/src/main/AndroidManifest.xml', 'utf8');
if (!c.includes('ACCESS_FINE_LOCATION')) {
  c = c.replace('<application', '<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />\n    <uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />\n    <application');
  fs.writeFileSync('android/app/src/main/AndroidManifest.xml', c);
  console.log('Permissions added');
} else {
  console.log('Permissions already exist');
}

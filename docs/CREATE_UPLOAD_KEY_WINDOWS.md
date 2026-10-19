# BUGÜN — Windows'ta ilk Android upload anahtarı

Bu yönerge, BUGÜN'ün ilk Google Play yayını içindir. **Bu anahtar gelecekteki güncellemeler için gerekir.** Dosyayı güvenli bir yerde en az iki ayrı yedekle saklayın; dosyayı, parolaları veya Base64 içeriğini GitHub deposuna/sohbete koymayın.

## 1. Anahtarı kendi Windows bilgisayarında oluştur

PowerShell açın. Önce Java anahtar aracının kullanılabildiğini kontrol edin:

```powershell
keytool -help
```

Komut bulunamazsa Android Studio/JDK ile gelen `keytool.exe` dosyasının yolunu kullanın. **Rastgele bir anahtar oluşturmayın veya daha sonra yeni bir anahtarla değiştirmeyin.**

Aşağıdaki komutu çalıştırın:

```powershell
keytool -genkeypair -v -keystore "$env:USERPROFILE\bugun-upload.jks" -keyalg RSA -keysize 2048 -validity 10000 -alias bugun-upload
```

- Keystore parolası belirleyin ve güvenli parola yöneticisine kaydedin.
- Bilgiler sorulduğunda doğru bilgileri girin.
- Anahtar parolası sorulursa ayrı bir parola belirleyip onu da güvenli şekilde kaydedin.
- Dosya burada oluşur: `%USERPROFILE%\bugun-upload.jks`.
- Dosyayı şifreli harici yedekleme/şifreli parola kasası gibi güvenli bir yere yedekleyin.

## 2. GitHub Actions için Base64 değerini üret

Aynı PowerShell penceresinde:

```powershell
$bytes = [System.IO.File]::ReadAllBytes("$env:USERPROFILE\bugun-upload.jks")
[Convert]::ToBase64String($bytes) | Set-Clipboard
```

Bu komut Base64 değerini panoya kopyalar. Değeri herhangi bir web sitesine yapıştırmayın; sadece aşağıdaki GitHub secret alanına yapıştırın.

## 3. Dört GitHub secret ekle

Depo: https://github.com/ssselimilhan-cell/Bu-G-n

**Settings → Secrets and variables → Actions → New repository secret** yolundan şu dört secret'ı ekleyin:

| Secret adı | Değer |
|---|---|
| `ANDROID_KEYSTORE_BASE64` | Bir önceki adımda panoya kopyalanan Base64 |
| `ANDROID_KEYSTORE_PASSWORD` | Keystore oluştururken belirlediğiniz keystore parolası |
| `ANDROID_KEY_ALIAS` | `bugun-upload` |
| `ANDROID_KEY_PASSWORD` | Anahtar için belirlediğiniz parola |

Parolaları sohbete yazmayın. Secret değerleri oluşturulduktan sonra GitHub bunları tekrar görüntülemez.

## 4. İmzalı AAB üret

https://github.com/ssselimilhan-cell/Bu-G-n/actions adresini açın. **BUGUN Google Play AAB** iş akışını seçin, **Run workflow** düğmesine basın ve branch olarak `bugun-codespaces-ready` seçili olduğundan emin olun.

İş akışı analiz, otomatik test, imza anahtarı doğrulaması ve AAB derlemesi yapar. Başarılı olduğunda `bugun-google-play-aab` adlı artifact'i indirin. İş akışı başarısız olursa hata kaydındaki ilk başarısız adım düzeltilmeden paketi yüklemeyin.

## Güvenlik notu

- `bugun-upload.jks` dosyasını GitHub deposuna yüklemeyin, e-postayla göndermeyin veya herkese açık paylaşmayın.
- Parolaları GitHub Issues, PR yorumları veya sohbet mesajlarına yazmayın.
- Anahtar dosyası ya da parolalar kaybolursa Google Play güncellemelerinde sorun yaşanabilir.
- Bu yönerge AAB üretimine yardımcı olur; uygulamanın Google Play incelemesini geçtiği anlamına gelmez.

.\apps\openssl.exe speed

for %%i in (sm3 sm4 aes-128-gcm aes-192-gcm aes-256-gcm) do (
    .\apps\openssl.exe speed -evp %%i
)

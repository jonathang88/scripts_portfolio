# detectar_dispositivos.sh

**Propósito:**  
Script educativo para descubrimiento preliminar de dispositivos en una red local. Realiza un barrido ARP para detectar equipos en la LAN y, opcionalmente, un escaneo ligero de puertos. Está pensado como herramienta de apoyo para auditorías en entornos controlados.

> **IMPORTANTE:** Este script es **solo para entornos que posees o donde tengas permiso explícito** para probar. No uses en redes de terceros sin autorización.

---

## Contenido
- `detectar_dispositivos.sh` — script principal (educativo).
- `examples/output-sanitized.txt` — ejemplo de salida con IPs y datos sensibles redacted.
- `README.md` — este archivo.

---

## Requisitos
Instala las dependencias (ejemplo para Debian/Ubuntu):
```bash
sudo apt update
sudo apt install -y arp-scan nmap awk sort
```

> Nota: Algunas operaciones utilizan `sudo`. Si ejecutas sin `sudo` el script caerá en modo no agresivo para minimizar impacto.

---

## Uso
```bash
# Modo seguro (por defecto)
./detectar_dispositivos.sh -i <interfaz>

# Modo agresivo (mayor información, requiere privilegios)
./detectar_dispositivos.sh -i <interfaz> -a

# Mostrar ayuda
./detectar_dispositivos.sh -h
```

**Ejemplo:**
```bash
./detectar_dispositivos.sh -i eth0
./detectar_dispositivos.sh -i wlan0 -a
```

---

## Comportamiento
- Por defecto realiza un `arp-scan --localnet` para obtener hosts y fabricantes.
- En modo no agresivo hace probes ligeros (ping + escaneo TCP de puertos comunes).
- Con `-a` activa escaneos más detallados (versioning y puertos top) y puede requerir `sudo`.
- El script **no** incluye fingerprinting agresivo por defecto (ej. `-O`) para evitar comportamiento intrusivo.

---

## Salida esperada (formato)
La salida está tabulada con columnas:
```
IP              | FABRICANTE                     | OS (approx)    | PUERTOS ABIERTOS     | TIPO
-----------------------------------------------------------------------------------------------------
192.0.2.5       | AcmeCorp                        | Desconocido    | 22,80                | Servidor Linux
...
```
En el repositorio incluimos `examples/output-sanitized.txt` como guía (IPs y datos sensibles reemplazados por `[REDACTED_IP]` y similares).

---

## Buenas prácticas antes de commitear
- **Sanitizar** cualquier salida o archivo de pruebas: reemplaza IPs, flags, claves y nombres reales por `[REDACTED...]`.
- Incluir un encabezado en cada script con propósitos y disclaimer.
- Ejecutar `detect-secrets` o `git-secrets` para evitar subir credenciales por error.
- Mantener material sensible en repositorio **privado** o en almacenamiento cifrado.

---

## Contribuciones
Puedes abrir PRs para mejorar robustez, añadir `--dry-run`, o ejemplos adicionales. Mantén el foco educativo y evita incluir PoC explotables.

---

## Licencia
MIT — ver archivo `LICENSE` en el repo.

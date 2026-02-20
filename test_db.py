import psycopg2
import os

def try_connect(host, dbname, user, password, port):
    print(f"\n--- Probando: host={host} dbname={dbname} user={user} port={port} ---")
    try:
        conn = psycopg2.connect(
            host=host,
            dbname=dbname,
            user=user,
            password=password,
            port=port,
            connect_timeout=3
        )
        print("¡CONEXIÓN EXITOSA!")
        conn.close()
        return True
    except Exception as e:
        print(f"Error detectado: {type(e).__name__}")
        try:
            print(f"Mensaje (UTF-8): {e}")
        except:
            print("Mensaje (Error de decodificación UTF-8)")
            if hasattr(e, 'args') and len(e.args) > 0:
                print(f"Bytes brutos (primer arg): {repr(e.args[0])}")
        return False

def diagnostic():
    configs = [
        # La configuración del proyecto
        {'host':'localhost', 'dbname':'inscripcion_db', 'user':'admin', 'password':'admin123', 'port':'5432'},
        # Usuario postgres por defecto
        {'host':'localhost', 'dbname':'postgres', 'user':'postgres', 'password':'', 'port':'5432'},
        # Usuario postgres con password admin123
        {'host':'localhost', 'dbname':'postgres', 'user':'postgres', 'password':'admin123', 'port':'5432'},
        # Sin password (trust)
        {'host':'localhost', 'dbname':'postgres', 'user':'admin', 'password':'', 'port':'5432'},
    ]
    
    for cfg in configs:
        if try_connect(**cfg):
            break

if __name__ == "__main__":
    diagnostic()

import mysql.connector
from pymongo import MongoClient
import pandas as pd


def clonar_justicia_a_mongodb():
    # Configuración de conexiones
    db_name_mysql = "justicia_genero_mex"
    db_name_mongo = "monitoreo_feminicidios"

    conn_mysql = None

    try:
        conn_mysql = mysql.connector.connect(
            host="localhost",
            port=3306,
            user="root",
            password="Jcl200509",
            database="justicia_genero_mex"
        )

        # 2. Extracción de datos
        query = "CALL sp_get_data_for_nosql()"
        df = pd.read_sql(query, conn_mysql)

        if df.empty:
            print("No hay datos procesados en MySQL para clonar.")
            return

        # 3. Reordenamiento de columnas
        columnas_ordenadas = [
            'folio_fiscalia', 'diagnostico_justicia', 'municipio',
            'medio_comision', 'sentencia_anios'
        ]
        df = df[columnas_ordenadas]

        # 4. Conexión a MongoDB y creación automática
        client_mongo = MongoClient("mongodb://localhost:27017/")
        db_mongo = client_mongo[db_name_mongo]
        coleccion = db_mongo['casos_detallados']

        # 5. Clonación de datos
        coleccion.delete_many({})

        registros = df.to_dict(orient='records')
        coleccion.insert_many(registros)

        print(f"ÉXITO: Se creó la base de datos '{db_name_mongo}' en MongoDB.")
        print(f"Se clonaron {len(registros)} documentos en la colección 'casos_detallados'.")
        print("--- Proceso finalizado correctamente ---")

    except mysql.connector.Error as err:
        print(f"Error en MySQL: {err}")
    except Exception as e:
        print(f"Error inesperado: {e}")
    finally:
        if conn_mysql and conn_mysql.is_connected():
            conn_mysql.close()
            print("--- Conexión MySQL cerrada ---")


if __name__ == '__main__':
    clonar_justicia_a_mongodb()
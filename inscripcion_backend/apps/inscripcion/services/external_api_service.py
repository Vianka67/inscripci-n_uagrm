import requests
import logging

logger = logging.getLogger(__name__)

class ExternalApiService:
    URL = "https://dev-serviciosinformix.uagrm.edu.bo/informix-services/"

    @staticmethod
    def query(query_string, variables=None):
        """
        Ejecuta una consulta GraphQL en el servidor externo.
        """
        payload = {
            "query": query_string,
            "variables": variables or {}
        }
        
        try:
            response = requests.post(ExternalApiService.URL, json=payload, timeout=10)
            response.raise_for_status()
            result = response.json()
            
            if "errors" in result:
                logger.error(f"Errores en respuesta GraphQL externa: {result['errors']}")
                return None
            
            return result.get("data")
        except requests.exceptions.RequestException as e:
            logger.error(f"Error conectando con el API externo: {e}")
            return None

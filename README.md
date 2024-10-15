# echML: Replicación de gráficos DT_14-24 - IECON, Udelar.

Este repositorio contiene el código para replicar los gráficos del Documento de Trabajo 14-24 del IECON a partir de los datos de la Encuesta Continua de Hogares descargados desde la web del INE.

Para replicar los gráficos:
1. Clonar el repositorio localmente
2. Descargar los datos originales desde la [web del INE]([https://example.com](https://www.gub.uy/instituto-nacional-estadistica/politicas-y-gestion/microdatos-metadatos-cuestionarios-manuales-ech-edicion)) y guardarlos en la carpeta "datos_originales" del repositorio local. Hasta 2020, descargar cada ECH en formato .SAV y guardar el archivo .SAV (no la carpeta comprimida). En 2021 descargar las bases del primer y segundo semestre (están separadas). Desde 2022 descargar las bases de implantación, la base seguimiento de cada mes y los pesos replicados Bootstrap (anuales y mensuales).
3. Editar el archivo ```master.do``` en la carpeta ```codigo``` indicando la dirección de la carpeta principal del repositorio local.
4. Ejecutar ```master.do```



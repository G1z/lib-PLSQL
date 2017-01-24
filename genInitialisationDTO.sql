/* Formatted on 23/01/2017 17:55:59 (QP5 v5.287) */
DECLARE
   objet             VARCHAR2 (30) := 'DEMANDE_MISSION';
   ret               VARCHAR2 (10000);
   w_owner           VARCHAR2 (30) := 'USRTQEMT';
   w_afficherOwner   BOOLEAN := TRUE;

   w_header          VARCHAR2 (30000) := NULL;
   w_body            VARCHAR2 (30000) := NULL;

   FUNCTION descriptionObjets (objet                    VARCHAR2,
                               own                      VARCHAR2,
                               w_afficherOwner          BOOLEAN,
                               w_header          IN OUT VARCHAR2,
                               w_body            IN OUT VARCHAR2)
      RETURN VARCHAR2
   IS
      ret         VARCHAR2 (30000) := NULL;
      w_type      VARCHAR2 (100);
      w_declare   VARCHAR2 (30000);
   BEGIN
      SELECT TYPECODE
        INTO w_type
        FROM ALL_TYPES
       WHERE type_name = objet AND OWNER = w_owner;

      --dbms_output.put_line(objet);

      IF w_type = 'OBJECT'
      THEN
         --ret := 'o_' || objet || ' := ' || objet || '(';
         w_header := w_header || 'o_' || objet || ' ';
         w_declare := 'o_' || objet || ' := ';

         IF w_afficherOwner
         THEN
            w_header := w_header || own || '.';
            w_declare := w_declare || own || '.';
         END IF;

         w_declare := w_declare || objet || '(';
         w_header := w_header || objet || ';' || CHR (13) || CHR (10);

         FOR r1 IN (  SELECT ATTR_NAME,
                             ATTR_TYPE_OWNER,
                             LENGTH,
                             ATTR_TYPE_NAME
                        FROM ALL_TYPE_ATTRS
                       WHERE type_name = objet AND owner = own
                    ORDER BY ATTR_NO)
         LOOP
            IF r1.ATTR_TYPE_OWNER IS NOT NULL                   -- Sous objets
            THEN
               ret :=
                     descriptionObjets (r1.ATTR_TYPE_NAME,
                                        own,
                                        w_afficherOwner,
                                        w_header,
                                        w_body)
                  || ret;
               --ret := ret || 'o_' || r1.ATTR_TYPE_NAME || ', '; --ret||descriptionObjets (r1.ATTR_TYPE_NAME);
               w_declare := w_declare || 'o_' || r1.ATTR_TYPE_NAME || ', ';
            ELSE
               --ret := ret || 'null /*' || r1.ATTR_NAME || '*/, ';
               w_declare := w_declare || 'null /*' || r1.ATTR_NAME || '*/, ';
            END IF;
         END LOOP;

         --ret := SUBSTR (ret, 0, LENGTH (ret) - 2);
         w_declare := SUBSTR (w_declare, 0, LENGTH (w_declare) - 2);
         --ret := ret || ');' || CHR (13) || CHR (10);
         w_declare := w_declare || ');' || CHR (13) || CHR (10);
      ELSIF w_type = 'COLLECTION'
      THEN
         FOR r1 IN (SELECT ELEM_TYPE_NAME, ELEM_TYPE_OWNER
                      FROM all_coll_types
                     WHERE TYPE_NAME = objet AND owner = own)
         LOOP
            /*IF r1.ELEM_TYPE_OWNER IS NOT NULL
            THEN
               w_header := w_header || 'A traiter : ' || objet || CHR (13) || CHR (10);
            ELSE*/
               w_header := w_header || 'o_' || objet || ' ';

               IF w_afficherOwner
               THEN
                  w_header := w_header || own || '.';
               END IF;

               w_header := w_header || objet || ';' || CHR (13) || CHR (10);
            --END IF;
         END LOOP;
      ELSE
         RETURN 'NOT FOUND : ' || objet;
      --DBMS_OUTPUT.put_line ('NOT FOUND : ' || objet);
      END IF;

      w_body := w_body || w_declare;
      RETURN ret;
   --DBMS_OUTPUT.put_line (ret);
   END;
BEGIN
   ret :=
      descriptionObjets (objet,
                         w_owner,
                         w_afficherOwner,
                         w_header,
                         w_body);
   --DBMS_OUTPUT.put_line (ret);
   DBMS_OUTPUT.put_line ('DECLARE');
   DBMS_OUTPUT.put_line (w_header);
   DBMS_OUTPUT.put_line ('BEGIN');
   DBMS_OUTPUT.put_line (w_body || 'END;');
--w_header
EXCEPTION
   WHEN OTHERS
   THEN
      DBMS_OUTPUT.put_line (SQLCODE || ' - ' || SQLERRM);
END;
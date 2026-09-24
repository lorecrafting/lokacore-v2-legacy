# Installs the mutant trigger of mutated_durable_runner.sh in the database file argv[0].
conn = LokaR1Server.Store.open(hd(System.argv()))

LokaR1Server.Store.exec!(conn, """
CREATE TRIGGER mutant AFTER INSERT ON receipts
WHEN NEW.result LIKE '%check_failed%' BEGIN
  UPDATE receipts SET result = replace(NEW.result, 'check_failed', 'check_fai1ed')
  WHERE instance = NEW.instance AND id = NEW.id;
END
""")

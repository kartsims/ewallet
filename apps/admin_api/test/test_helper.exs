{:ok, _} = Application.ensure_all_started(:ex_machina)
ExUnit.start()
Ecto.Adapters.SQL.Sandbox.mode(EWalletConfig.Repo, :manual)
Ecto.Adapters.SQL.Sandbox.mode(EWalletDB.Repo, :manual)
Ecto.Adapters.SQL.Sandbox.mode(LocalLedgerDB.Repo, :manual)

if System.get_env("USE_JUNIT") do
  ExUnit.configure(formatters: [JUnitFormatter, ExUnit.CLIFormatter])
end

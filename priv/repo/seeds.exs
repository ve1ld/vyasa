# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# Inside the script, you can read and write to any of your
# repositories directly:
#
#     Vyasa.Repo.insert!(%Vyasa.SomeSchema{})
#
# We recommend using the bang functions (`insert!`, `update!`
# and so on) as they will fail if something goes wrong.
require Logger

try do
  ExAws.S3.put_bucket("vyasa", "ap-southeast-1")
  |> ExAws.request!()

  IO.inspect("ok good", "bucket creation")
rescue
  e ->
    Logger.debug(Exception.format(:error, e, __STACKTRACE__))
end

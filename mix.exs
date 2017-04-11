defmodule RadioThermostat.Mixfile do
  use Mix.Project

  def project do
    [app: :radio_thermostat,
     version: "0.1.1",
     elixir: "~> 1.3",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     description: description(),
     package: package(),
     deps: deps()]
  end

  # Configuration for the OTP application
  #
  # Type "mix help compile.app" for more information
  def application do
    [applications: [:logger, :httpoison, :poison]]
  end

  def description do
      """
      Communicate with a Radio Thermostat over the LAN
      """
  end

  def package do
    [
      name: :radio_thermostat,
      files: ["lib", "mix.exs", "README*"],
      maintainers: ["Christopher Steven Coté"],
      licenses: ["Apache License 2.0"],
      links: %{"GitHub" => "https://github.com/NationalAssociationOfRealtors/radio_thermostat",
          "Docs" => "https://github.com/NationalAssociationOfRealtors/radio_thermostat"}
    ]
  end

  defp deps do
    [
      {:httpoison, "~> 0.11.1"},
      {:poison, "~> 2.1"},
      {:ex_doc, ">= 0.0.0", only: :dev}
    ]
  end
end

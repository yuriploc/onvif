defmodule Onvif.Media.Ver20.Media do
  @moduledoc """
  Interface for making requests to the 2.0 version of Onvif Media Service

  https://www.onvif.org/ver20/media/wsdl/media.wsdl
  """
  require Logger

  alias Onvif.Device

  @endpoint "/onvif/media"

  @namespaces [
    "xmlns:tr2": "http://www.onvif.org/ver20/media/wsdl",
    "xmlns:tt": "http://www.onvif.org/ver10/schema"
  ]

  @spec request(Device.t(), list, :basic_auth | :digest_auth | :no_auth | :xml_auth, module()) ::
          {:ok, any} | {:error, map()}
  def request(%Device{} = device, args \\ [], auth \\ :xml_auth, operation) do
    content = generate_content(operation, args)
    soap_action = operation.soap_action()

    (device.address <> device.media_service_path)
    |> Onvif.API.client(auth)
    |> Tesla.request(
      method: :post,
      headers: [{"Content-Type", "application/soap+xml"}, {"SOAPAction", soap_action}],
      body: %Onvif.Request{content: content, namespaces: @namespaces}
    )
    |> parse_response(operation)
  end

  defp generate_content(operation, args), do: apply(operation, :request_body, args)

  defp parse_response({:ok, %{status: 200, body: body}}, operation) do
    operation.response(body)
  end

  defp parse_response({:ok, %{status: status_code, body: body}}, operation)
       when status_code >= 400,
       do:
         {:error,
          %{
            status: status_code,
            reason: "Received #{status_code} from #{operation}",
            response: body
          }}

  defp parse_response({:error, response}, operation) do
    {:error, %{status: nil, reason: "Error performing #{operation}", response: response}}
  end
end

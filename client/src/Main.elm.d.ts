export type JsonObject = { [Key in string]?: JsonValue };
export type JsonArray = JsonValue[];

/**
Matches any valid JSON value.
Source: https://github.com/sindresorhus/type-fest/blob/master/source/basic.d.ts
*/
export type JsonValue =
  | string
  | number
  | boolean
  | null
  | JsonObject
  | JsonArray;

export interface ElmApp {
  ports: {
    interopFromElm: PortFromElm<FromElm>;
    interopToElm: PortToElm<ToElm>;
    [key: string]: UnknownPort;
  };
}

export type FromElm = { tag : "GetToken" } | { data : { file : { lastModified : number; mime : string; name : string; size : number; value : JsonValue } }; tag : "ConvertImage" } | { data : { id : string }; tag : "CloseDialog" } | { data : { id : string }; tag : "OpenDialog" };

export type ToElm = { tag : "authenticatedUser"; username : string } | { image : string | JsonValue; tag : "convertedImage" } | ({ tag : "gotToken" } & ({ state : "error" } | { state : "registered"; token : JsonValue }));

export type Flags = { state : { state : "error" } | { state : "registered"; token : JsonValue }; timestamp : number };

export namespace Main {
  function init(options: { node?: HTMLElement | null; flags: Flags }): ElmApp;
}

export as namespace Elm;

export { Elm };

export type UnknownPort = PortFromElm<unknown> | PortToElm<unknown> | undefined;

export type PortFromElm<Data> = {
  subscribe(callback: (fromElm: Data) => void): void;
  unsubscribe(callback: (fromElm: Data) => void): void;
};

export type PortToElm<Data> = { send(data: Data): void };

import "./style.css";
import { Elm } from "./src/Main.elm";

if (process.env.NODE_ENV === "development") {
  const ElmDebugTransform = await import("elm-debug-transformer");

  ElmDebugTransform.register({
    simple_mode: true,
  });
}

type State = { state: "registered"; token: string } | { state: "error" };

type JsonResponse = { token: string };

fetch("__BACKEND_ENDPOINT__/auth/get_jwt")
  .then((res) => {
    if (res.ok) {
      res.json().then((json: JsonResponse) => {
        startApp({ state: "registered", token: json.token });
      });
    } else {
      startApp({ state: "error" });
    }
  })
  .catch(() => {
    startApp({ state: "error" });
  });

const openDialog = (id) => {
  const dialog = document.querySelector(`#${id}`) as HTMLDialogElement;

  if (dialog) {
    if (!dialog.open) {
      dialog.showModal();
      dialog.addEventListener("cancel", (event) => {
        event.preventDefault();
      });
    }
  } else {
    console.error("element specified not found ");
  }
};

const closeDialog = (id) => {
  const dialog = document.querySelector(`#${id}`) as HTMLDialogElement;

  if (dialog) {
    if (dialog.open) {
      dialog.close();
    }
  } else {
    console.error("element specified not found ");
  }
};

function resizeImage(src) {
  return new Promise<string | null>((resolve, reject) => {
    const WIDTH = 240;
    // const HEIGHT = 800
    let reader = new FileReader();

    reader.onload = (e) => {
      const image = document.createElement("img") as HTMLImageElement;
      image.onload = () => {
        const elem = document.createElement("canvas");
        const scaleFactor = WIDTH / image.width;
        elem.width = WIDTH;
        elem.height = image.height * scaleFactor;

        const ctx = elem.getContext("2d");

        if (ctx) {
          ctx.drawImage(image, 0, 0, WIDTH, image.height * scaleFactor);

          const result = ctx.canvas.toDataURL("image/jpeg", 0.85);
          resolve(result);
        } else {
          resolve(null);
        }
      };
      if (e.target?.result) {
        image.src = e.target?.result as string;
      }
    };
    reader.onerror = (e) => {
      console.error("Caught an error when resizing an image ", e);
      resolve(null);
    };
    reader.readAsDataURL(src.value);
  });
}

async function startApp(state: State) {
  let elm_div = <HTMLElement>document.querySelector("#app div");

  if (elm_div) {
    const app = Elm.Main.init({
      node: elm_div,
      flags: { state, timestamp: Date.now() },
    });

    app.ports.interopFromElm.subscribe(async (fromElm) => {
      switch (fromElm.tag) {
        case "OpenDialog":
          openDialog(fromElm.data.id);
          break;
        case "CloseDialog":
          closeDialog(fromElm.data.id);
          break;
        case "ConvertImage":
          resizeImage(fromElm.data.file).then((resized: string | null) => {
            app.ports.interopToElm.send({
              tag: "convertedImage",
              image: resized,
            });
          });
          break;
        case "GetToken":
          fetch("__BACKEND_ENDPOINT__/auth/get_jwt")
            .then((res) => {
              if (res.ok) {
                res.json().then((json: JsonResponse) => {
                  app.ports.interopToElm.send({
                    tag: "gotToken",
                    state: "registered",
                    token: json.token,
                  });
                });
              } else {
                app.ports.interopToElm.send({
                  tag: "gotToken",
                  state: "error",
                });
              }
            })
            .catch(() => {
              app.ports.interopToElm.send({
                tag: "gotToken",
                state: "error",
              });
            });
          break;
      }
    });
  }
}

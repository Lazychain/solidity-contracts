import { Buffer } from "buffer";
import { QueryClient, QueryClientProvider } from "@tanstack/react-query";
import React from "react";
import ReactDOM from "react-dom/client";
import { WagmiProvider } from "wagmi";

import App from "./App.tsx";
import { config } from "./wagmi.ts";

import "./index.css";
import { BrowserRouter } from "react-router-dom";
import { Toaster } from "./components/ui/toaster.tsx";

(globalThis as any).Buffer = Buffer;

const queryClient = new QueryClient();

const root = document.getElementById("root");

if (root != null) {
  ReactDOM.createRoot(root).render(
    <React.StrictMode>
      <BrowserRouter>
        <WagmiProvider config={config}>
          <QueryClientProvider client={queryClient}>
            <Toaster />
            <App />
          </QueryClientProvider>
        </WagmiProvider>
      </BrowserRouter>
    </React.StrictMode>
  );
}

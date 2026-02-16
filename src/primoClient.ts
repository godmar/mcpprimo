import { Config } from "./config.js";

export interface PrimoSearchParams {
  q: string;
  limit?: number;
  offset?: number;
  sort?: string;
  qInclude?: string;
  qExclude?: string;
  lang?: string;
}

export interface PrimoSearchResult {
  status: number;
  data: unknown;
  apiRemaining?: string;
}

export async function searchPrimo(
  config: Config,
  params: PrimoSearchParams,
): Promise<PrimoSearchResult> {
  const url = new URL("/primo/v1/search", config.primoBaseUrl);

  url.searchParams.set("apikey", config.primoApiKey);
  url.searchParams.set("vid", config.primoVid);
  url.searchParams.set("tab", config.primoTab);
  url.searchParams.set("scope", config.primoScope);
  url.searchParams.set("q", params.q);

  if (config.primoInst) {
    url.searchParams.set("inst", config.primoInst);
  }
  if (params.limit !== undefined) {
    url.searchParams.set("limit", String(params.limit));
  }
  if (params.offset !== undefined) {
    url.searchParams.set("offset", String(params.offset));
  }
  if (params.sort) {
    url.searchParams.set("sort", params.sort);
  }
  if (params.qInclude) {
    url.searchParams.set("qInclude", params.qInclude);
  }
  if (params.qExclude) {
    url.searchParams.set("qExclude", params.qExclude);
  }
  if (params.lang) {
    url.searchParams.set("lang", params.lang);
  }

  const response = await fetch(url.toString(), {
    method: "GET",
    headers: { Accept: "application/json" },
  });

  const data = await response.json();
  const apiRemaining =
    response.headers.get("X-Exl-Api-Remaining") ?? undefined;

  return { status: response.status, data, apiRemaining };
}

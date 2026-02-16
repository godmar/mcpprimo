export interface Config {
  primoApiKey: string;
  primoBaseUrl: string;
  primoVid: string;
  primoTab: string;
  primoScope: string;
  primoInst: string;
  port: number;
}

export function loadConfig(): Config {
  const primoApiKey = process.env.PRIMO_API_KEY;
  if (!primoApiKey) {
    throw new Error("PRIMO_API_KEY environment variable is required");
  }

  return {
    primoApiKey,
    primoBaseUrl:
      process.env.PRIMO_BASE_URL || "https://api-na.hosted.exlibrisgroup.com",
    primoVid: process.env.PRIMO_VID || "",
    primoTab: process.env.PRIMO_TAB || "",
    primoScope: process.env.PRIMO_SCOPE || "",
    primoInst: process.env.PRIMO_INST || "",
    port: parseInt(process.env.PORT || "3000", 10),
  };
}

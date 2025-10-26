
import { GoogleGenerativeAI, ChatSession, GenerateContentResult, Part } from '@google/generative-ai';
import { MaterialType, PickupDetails } from '../types';
import { VALID_MATERIALS } from '../constants';

if (!process.env.API_KEY) {
  throw new Error("API_KEY environment variable not set");
}

const ai = new GoogleGenerativeAI(process.env.API_KEY);

let chat: ChatSession | null = null;

const getChat = () => {
    if (!chat) {
        const model = ai.getGenerativeModel({ model: "gemini-pro" });
        const systemInstruction = `You are a friendly and helpful customer service assistant for K&L Recycling.
                Your goal is to answer user questions accurately based on the following information.
                Do not invent information. If you don't know the answer, say "I'm sorry, I don't have that information, but you can call us at (555) 123-4567 for more details."

                **K&L Recycling Information:**
                - **Locations & Hours:**
                  - Downtown Yard: 123 Industrial Ave, Open Mon-Fri 8am-5pm, Sat 9am-1pm.
                  - Northside Center: 456 Scrapper Blvd, Open Mon-Sat 7am-6pm.
                - **Contact:** Phone: (555) 123-4567
                - **Accepted Materials:** Steel, Aluminum (including cans), Copper (wire and pipe), Brass, Lead, Stainless Steel.
                - **Prohibited Materials:** We do not accept refrigerators, hazardous waste, tires, TVs, or any electronics.
                - **Services:** Roll-off container rental (20, 30, 40-yard), schedule pickups for large loads.
                - **Current Prices (as of today):**
                  - Steel: $0.10/lb
                  - Aluminum: $0.65/lb
                  - Copper: $3.50/lb
                  - Brass: $2.20/lb
                  - Lead: $0.80/lb
                  - Stainless Steel: $0.40/lb
                
                Keep your answers concise and to the point.
                `;
        chat = model.startChat({
            systemInstruction: systemInstruction,
        });
    }
    return chat;
}

export const getChatbotResponse = async (message: string): Promise<string> => {
    try {
        const chatInstance = getChat();
        const result: GenerateContentResult = await chatInstance.sendMessage(message);
        const response = result.response;
        return response.text();
    } catch (error) {
        console.error("Error getting chatbot response:", error);
        return "I'm having a little trouble connecting right now. Please try again in a moment.";
    }
};


function fileToGenerativePart(file: File): Promise<Part> {
  return new Promise((resolve, reject) => {
    const reader = new FileReader();
    reader.onload = () => {
      if (typeof reader.result !== 'string') {
        return reject(new Error("Failed to read file as base64 string"));
      }
      const base64Data = reader.result.split(',')[1];
      resolve({
        inlineData: {
          data: base64Data,
          mimeType: file.type,
        },
      });
    };
    reader.onerror = (err) => reject(err);
    reader.readAsDataURL(file);
  });
}

export const identifyMaterial = async (imageFile: File): Promise<MaterialType> => {
  try {
    const model = ai.getGenerativeModel({ model: "gemini-pro-vision" });
    const imagePart = await fileToGenerativePart(imageFile);
    const prompt = `Analyze this image of scrap metal. Identify the primary material. Respond with only one of the following words: ${VALID_MATERIALS.join(', ')}.`;

    const result = await model.generateContent([prompt, imagePart]);
    const response = result.response;
    const text = response.text().trim();
    
    const identifiedMaterial = VALID_MATERIALS.find(m => text.toLowerCase().includes(m.toLowerCase()));

    return identifiedMaterial || MaterialType.OTHER;

  } catch (error) {
    console.error("Error identifying material:", error);
    return MaterialType.UNKNOWN;
  }
};

export const extractPickupDetails = async (notes: string): Promise<PickupDetails> => {
  try {
    const model = ai.getGenerativeModel({
        model: "gemini-pro",
        generationConfig: {
            responseMimeType: "application/json",
        }
    });
    const prompt = `Extract the following entities from this user request for a scrap metal pickup:
- address (the full street address for the pickup)
- container_size (e.g., "20-yard", "30 yard", "40-yard roll-off")
- special_instructions (any extra details like gate codes, placement instructions)
- requested_date (the requested day or time for the pickup, like "Friday morning", "next Tuesday")

Text: "${notes}"

Return a JSON object with the extracted entities. If an entity is not found, omit it from the JSON.`;

    const result = await model.generateContent(prompt);
    const response = result.response;
    const jsonText = response.text();
    const parsedJson = JSON.parse(jsonText);
    return parsedJson as PickupDetails;

  } catch (error) {
    console.error("Error extracting pickup details:", error);
    return {};
  }
};

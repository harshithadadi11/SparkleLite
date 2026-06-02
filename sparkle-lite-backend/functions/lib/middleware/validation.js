"use strict";
var __createBinding = (this && this.__createBinding) || (Object.create ? (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    var desc = Object.getOwnPropertyDescriptor(m, k);
    if (!desc || ("get" in desc ? !m.__esModule : desc.writable || desc.configurable)) {
      desc = { enumerable: true, get: function() { return m[k]; } };
    }
    Object.defineProperty(o, k2, desc);
}) : (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    o[k2] = m[k];
}));
var __setModuleDefault = (this && this.__setModuleDefault) || (Object.create ? (function(o, v) {
    Object.defineProperty(o, "default", { enumerable: true, value: v });
}) : function(o, v) {
    o["default"] = v;
});
var __importStar = (this && this.__importStar) || (function () {
    var ownKeys = function(o) {
        ownKeys = Object.getOwnPropertyNames || function (o) {
            var ar = [];
            for (var k in o) if (Object.prototype.hasOwnProperty.call(o, k)) ar[ar.length] = k;
            return ar;
        };
        return ownKeys(o);
    };
    return function (mod) {
        if (mod && mod.__esModule) return mod;
        var result = {};
        if (mod != null) for (var k = ownKeys(mod), i = 0; i < k.length; i++) if (k[i] !== "default") __createBinding(result, mod, k[i]);
        __setModuleDefault(result, mod);
        return result;
    };
})();
Object.defineProperty(exports, "__esModule", { value: true });
exports.deleteAccountSchema = exports.generateSummarySchema = exports.generateInsightSchema = void 0;
exports.validateRequest = validateRequest;
const functions = __importStar(require("firebase-functions"));
const zod_1 = require("zod");
function validateRequest(schema, data) {
    const result = schema.safeParse(data);
    if (!result.success) {
        throw new functions.https.HttpsError('invalid-argument', `Invalid request: ${result.error.issues.map(i => i.message).join(', ')}`);
    }
    return result.data;
}
// Zod schemas for all callable function inputs
exports.generateInsightSchema = zod_1.z.object({
    logIds: zod_1.z.array(zod_1.z.string().min(1)).min(1).max(30),
});
exports.generateSummarySchema = zod_1.z.object({
    questionsToAsk: zod_1.z.array(zod_1.z.string()).optional(),
    userNotes: zod_1.z.string().max(2000).optional(),
});
exports.deleteAccountSchema = zod_1.z.object({
    confirmationText: zod_1.z.literal('DELETE'),
});
//# sourceMappingURL=validation.js.map
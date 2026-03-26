import axios from 'axios';
import { API_BASE_URL } from './env';
export function apiClient(token){return axios.create({baseURL: API_BASE_URL, headers: token ? {Authorization:`Bearer ${token}`} : {}})}

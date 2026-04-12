const API_URL = import.meta.env.VITE_API_URL || 'http://localhost:8000/api/v1';

interface RequestOptions extends RequestInit {
  params?: Record<string, string>;
}

export const apiClient = {
  async request(endpoint: string, options: RequestOptions = {}) {
    const token = localStorage.getItem('token');
    
    const headers = new Headers(options.headers);
    if (token) {
      headers.set('Authorization', `Bearer ${token}`);
    }
    if (!(options.body instanceof FormData)) {
      headers.set('Content-Type', 'application/json');
    }

    const url = new URL(`${API_URL}${endpoint}`);
    if (options.params) {
      Object.entries(options.params).forEach(([key, value]) => {
        url.searchParams.append(key, value);
      });
    }

    try {
      const response = await fetch(url.toString(), {
        ...options,
        headers,
      });

      const data = await response.json();

      if (!response.ok) {
        throw new Error(data.message || 'Something went wrong');
      }

      return data;
    } catch (error) {
      console.error('API Request Error:', error);
      throw error;
    }
  },

  get(endpoint: string, options: RequestOptions = {}) {
    return this.request(endpoint, { ...options, method: 'GET' });
  },

  post(endpoint: string, body?: any, options: RequestOptions = {}) {
    return this.request(endpoint, {
      ...options,
      method: 'POST',
      body: body instanceof FormData ? body : JSON.stringify(body),
    });
  },

  patch(endpoint: string, body?: any, options: RequestOptions = {}) {
    return this.request(endpoint, {
      ...options,
      method: 'PATCH',
      body: body instanceof FormData ? body : JSON.stringify(body),
    });
  },

  delete(endpoint: string, options: RequestOptions = {}) {
    return this.request(endpoint, { ...options, method: 'DELETE' });
  },
};
